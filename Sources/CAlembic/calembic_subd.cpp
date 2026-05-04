#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicOSubD { OSubD subd; CAlembicOSubD(OObject p, const std::string& n) : subd(p, n) {} };
struct CAlembicISubD { ISubD subd; CAlembicISubD(IObject o) : subd(o, kWrapExisting) {} };

std::shared_ptr<CAlembicOSubD> calembic_create_subd(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOSubD>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_subd: ") + e.what()); return nullptr; }
}

int calembic_subd_set(const std::shared_ptr<CAlembicOSubD>& subd, const CAlembicSubDSample& sample) {
    try {
        OSubDSchema::Sample s;
        std::vector<Imath::V3f> pos; pos.reserve(sample.positions.size()); for (auto& p : sample.positions) pos.push_back(Imath::V3f(p.x,p.y,p.z));
        s.setPositions(V3fArraySample(pos.data(), pos.size()));
        s.setFaceIndices(Int32ArraySample(sample.faceIndices.data(), sample.faceIndices.size()));
        s.setFaceCounts(Int32ArraySample(sample.faceCounts.data(), sample.faceCounts.size()));
        if (sample.hasCreaseIndices && !sample.creaseIndices.empty()) s.setCreaseIndices(Int32ArraySample(sample.creaseIndices.data(), sample.creaseIndices.size()));
        if (sample.hasCreaseLengths && !sample.creaseLengths.empty()) s.setCreaseLengths(Int32ArraySample(sample.creaseLengths.data(), sample.creaseLengths.size()));
        if (sample.hasCreaseSharpnesses && !sample.creaseSharpnesses.empty()) s.setCreaseSharpnesses(FloatArraySample(sample.creaseSharpnesses.data(), sample.creaseSharpnesses.size()));
        if (sample.hasCornerIndices && !sample.cornerIndices.empty()) s.setCornerIndices(Int32ArraySample(sample.cornerIndices.data(), sample.cornerIndices.size()));
        if (sample.hasCornerSharpnesses && !sample.cornerSharpnesses.empty()) s.setCornerSharpnesses(FloatArraySample(sample.cornerSharpnesses.data(), sample.cornerSharpnesses.size()));
        s.setInterpolateBoundary(static_cast<GeometryScope>(sample.interpolation));
        subd->subd.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("subd_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicISubD> calembic_object_as_subd(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicISubD>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_subd: ") + e.what()); return nullptr; }
}

uint32_t calembic_subd_num_samples(const std::shared_ptr<CAlembicISubD>& subd) {
    try { return static_cast<uint32_t>(subd->subd.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_subd_get(const std::shared_ptr<CAlembicISubD>& subd, uint32_t index, CAlembicSubDSample* out) {
    try {
        ISubDSchema::Sample sample; subd->subd.getSchema().get(sample, makeSelector(index));
        CAlembicSubDSample result; result.interpolation = CAlembicGeometryScope_Vertex;
        auto posPtr = sample.getPositions(); if (posPtr && posPtr->size() > 0) { for (size_t i = 0; i < posPtr->size(); i++) result.positions.push_back(fromV3f((*posPtr)[i])); }
        auto fiPtr = sample.getFaceIndices(); if (fiPtr) result.faceIndices.assign(fiPtr->get(), fiPtr->get() + fiPtr->size());
        auto fcPtr = sample.getFaceCounts(); if (fcPtr) result.faceCounts.assign(fcPtr->get(), fcPtr->get() + fcPtr->size());
        auto ciPtr = sample.getCreaseIndices(); if (ciPtr) { result.creaseIndices.assign(ciPtr->get(), ciPtr->get() + ciPtr->size()); result.hasCreaseIndices = true; }
        auto clPtr = sample.getCreaseLengths(); if (clPtr) { result.creaseLengths.assign(clPtr->get(), clPtr->get() + clPtr->size()); result.hasCreaseLengths = true; }
        auto csPtr = sample.getCreaseSharpnesses(); if (csPtr) { result.creaseSharpnesses.assign(csPtr->get(), csPtr->get() + csPtr->size()); result.hasCreaseSharpnesses = true; }
        auto ci2Ptr = sample.getCornerIndices(); if (ci2Ptr) { result.cornerIndices.assign(ci2Ptr->get(), ci2Ptr->get() + ci2Ptr->size()); result.hasCornerIndices = true; }
        auto cs2Ptr = sample.getCornerSharpnesses(); if (cs2Ptr) { result.cornerSharpnesses.assign(cs2Ptr->get(), cs2Ptr->get() + cs2Ptr->size()); result.hasCornerSharpnesses = true; }
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("subd_get: ") + e.what()); return -1; }
}
