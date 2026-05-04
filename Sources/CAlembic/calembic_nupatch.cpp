#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicONuPatch { ONuPatch nupatch; CAlembicONuPatch(OObject p, const std::string& n) : nupatch(p, n) {} };
struct CAlembicINuPatch { INuPatch nupatch; CAlembicINuPatch(IObject o) : nupatch(o, kWrapExisting) {} };

std::shared_ptr<CAlembicONuPatch> calembic_create_nupatch(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicONuPatch>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_nupatch: ") + e.what()); return nullptr; }
}

int calembic_nupatch_set(const std::shared_ptr<CAlembicONuPatch>& nupatch, const CAlembicNuPatchSample& sample) {
    try {
        ONuPatchSchema::Sample s; s.setUOrder(sample.uOrder); s.setVOrder(sample.vOrder);
        s.setUKnot(FloatArraySample(sample.uKnot.data(), sample.uKnot.size()));
        s.setVKnot(FloatArraySample(sample.vKnot.data(), sample.vKnot.size()));
        std::vector<Imath::V3f> pos; pos.reserve(sample.positions.size()); for (auto& p : sample.positions) pos.push_back(Imath::V3f(p.x,p.y,p.z));
        s.setPositions(V3fArraySample(pos.data(), pos.size()));
        if (sample.hasPositionWeights && !sample.positionWeights.empty()) s.setPositionWeights(FloatArraySample(sample.positionWeights.data(), sample.positionWeights.size()));
        if (sample.hasNormals && !sample.normals.empty()) { std::vector<Imath::V3f> n; for (auto& v : sample.normals) n.push_back(Imath::V3f(v.x,v.y,v.z)); s.setNormals(ON3fGeomParam::Sample(N3fArraySample(n.data(), n.size()), kVertexScope)); }
        if (sample.hasUVs && !sample.uvs.empty()) { std::vector<Imath::V2f> u; for (auto& v : sample.uvs) u.push_back(toV2f(v)); s.setUVs(OV2fGeomParam::Sample(V2fArraySample(u.data(), u.size()), kVertexScope)); }
        if (sample.selfBoundsSet) s.setSelfBounds(toBox3d(sample.selfBounds));
        nupatch->nupatch.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("nupatch_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicINuPatch> calembic_object_as_nupatch(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicINuPatch>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_nupatch: ") + e.what()); return nullptr; }
}

uint32_t calembic_nupatch_num_samples(const std::shared_ptr<CAlembicINuPatch>& nupatch) {
    try { return static_cast<uint32_t>(nupatch->nupatch.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_nupatch_get(const std::shared_ptr<CAlembicINuPatch>& nupatch, uint32_t index, CAlembicNuPatchSample* out) {
    try {
        INuPatchSchema::Sample sample; nupatch->nupatch.getSchema().get(sample, makeSelector(index));
        CAlembicNuPatchSample result; result.uOrder=sample.getUOrder(); result.vOrder=sample.getVOrder(); result.selfBoundsSet=false;
        auto ukPtr = sample.getUKnot(); if (ukPtr) result.uKnot.assign(ukPtr->get(), ukPtr->get() + ukPtr->size());
        auto vkPtr = sample.getVKnot(); if (vkPtr) result.vKnot.assign(vkPtr->get(), vkPtr->get() + vkPtr->size());
        auto posPtr = sample.getPositions(); if (posPtr && posPtr->size() > 0) { for (size_t i=0; i<posPtr->size(); i++) result.positions.push_back(fromV3f((*posPtr)[i])); }
        auto pwPtr = sample.getPositionWeights(); if (pwPtr && pwPtr->size() > 0) { result.positionWeights.assign(pwPtr->get(), pwPtr->get() + pwPtr->size()); result.hasPositionWeights = true; }
        { auto& sc = nupatch->nupatch.getSchema(); IN3fGeomParam p = sc.getNormalsParam(); if (p.valid()) { IN3fGeomParam::Sample ns; p.getExpanded(ns, makeSelector(index)); auto nPtr = ns.getVals(); if (nPtr && nPtr->size() > 0) { for (size_t i=0; i<nPtr->size(); i++) result.normals.push_back({(*nPtr)[i].x,(*nPtr)[i].y,(*nPtr)[i].z}); result.hasNormals = true; } } }
        { auto& sc = nupatch->nupatch.getSchema(); IV2fGeomParam p = sc.getUVsParam(); if (p.valid()) { IV2fGeomParam::Sample us; p.getExpanded(us, makeSelector(index)); auto uPtr = us.getVals(); if (uPtr && uPtr->size() > 0) { for (size_t i=0; i<uPtr->size(); i++) result.uvs.push_back(fromV2f((*uPtr)[i])); result.hasUVs = true; } } }
        if (sample.getSelfBounds().hasVolume()) { result.selfBounds = fromBox3d(sample.getSelfBounds()); result.selfBoundsSet = true; }
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("nupatch_get: ") + e.what()); return -1; }
}
