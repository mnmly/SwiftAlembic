#include "calembic_shared.h"

using namespace Alembic::Abc;
using namespace Alembic::AbcGeom;

struct CAlembicOPolyMesh { OPolyMesh mesh; CAlembicOPolyMesh(OObject p, const std::string& n) : mesh(p, n) {} };
struct CAlembicIPolyMesh { IPolyMesh mesh; CAlembicIPolyMesh(IObject o) : mesh(o, kWrapExisting) {} };

std::shared_ptr<CAlembicOPolyMesh> calembic_create_polymesh(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOPolyMesh>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_polymesh: ") + e.what()); return nullptr; }
}

int calembic_polymesh_set(const std::shared_ptr<CAlembicOPolyMesh>& mesh, const CAlembicPolyMeshSample& sample) {
    try {
        OPolyMeshSchema::Sample s;
        // Declare all temp vectors at outer scope so their data stays valid until schema.set(s).
        std::vector<Imath::V3f> pos, normals, velocities;
        std::vector<Imath::V2f> uvs;
        if (!sample.positions.empty()) {
            pos.reserve(sample.positions.size());
            for (auto& p : sample.positions) pos.push_back(toV3f(p));
            s.setPositions(V3fArraySample(pos.data(), pos.size()));
        }
        if (!sample.faceIndices.empty()) s.setFaceIndices(Int32ArraySample(sample.faceIndices.data(), sample.faceIndices.size()));
        if (!sample.faceCounts.empty()) s.setFaceCounts(Int32ArraySample(sample.faceCounts.data(), sample.faceCounts.size()));
        if (sample.hasNormals && !sample.normals.empty()) {
            normals.reserve(sample.normals.size());
            for (auto& v : sample.normals) normals.push_back(Imath::V3f(v.x, v.y, v.z));
            s.setNormals(ON3fGeomParam::Sample(N3fArraySample(normals.data(), normals.size()), kVertexScope));
        }
        if (sample.hasUVs && !sample.uvs.empty()) {
            uvs.reserve(sample.uvs.size());
            for (auto& v : sample.uvs) uvs.push_back(toV2f(v));
            s.setUVs(OV2fGeomParam::Sample(V2fArraySample(uvs.data(), uvs.size()), kFacevaryingScope));
        }
        if (sample.hasVelocities && !sample.velocities.empty()) {
            velocities.reserve(sample.velocities.size());
            for (auto& v : sample.velocities) velocities.push_back(toV3f(v));
            s.setVelocities(V3fArraySample(velocities.data(), velocities.size()));
        }
        if (sample.selfBoundsSet) s.setSelfBounds(toBox3d(sample.selfBounds));
        mesh->mesh.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("polymesh_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicIPolyMesh> calembic_object_as_polymesh(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicIPolyMesh>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_polymesh: ") + e.what()); return nullptr; }
}

uint32_t calembic_polymesh_num_samples(const std::shared_ptr<CAlembicIPolyMesh>& mesh) {
    try { return static_cast<uint32_t>(mesh->mesh.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_polymesh_get(const std::shared_ptr<CAlembicIPolyMesh>& mesh, uint32_t index, CAlembicPolyMeshSample* out) {
    try {
        IPolyMeshSchema::Sample sample;
        mesh->mesh.getSchema().get(sample, makeSelector(index));
        CAlembicPolyMeshSample result;
        result.selfBoundsSet = false;
        auto posPtr = sample.getPositions(); if (posPtr && posPtr->size() > 0) { result.positions.reserve(posPtr->size()); for (size_t i = 0; i < posPtr->size(); i++) result.positions.push_back(fromV3f((*posPtr)[i])); }
        auto fiPtr = sample.getFaceIndices(); if (fiPtr) result.faceIndices.assign(fiPtr->get(), fiPtr->get() + fiPtr->size());
        auto fcPtr = sample.getFaceCounts(); if (fcPtr) result.faceCounts.assign(fcPtr->get(), fcPtr->get() + fcPtr->size());
        auto velPtr = sample.getVelocities(); if (velPtr && velPtr->size() > 0) { for (size_t i = 0; i < velPtr->size(); i++) result.velocities.push_back(fromV3f((*velPtr)[i])); result.hasVelocities = true; }
        auto& schema = mesh->mesh.getSchema();
        { IN3fGeomParam p = schema.getNormalsParam(); if (p.valid()) { IN3fGeomParam::Sample ns; p.getExpanded(ns, makeSelector(index)); auto nPtr = ns.getVals(); if (nPtr && nPtr->size() > 0) { for (size_t i = 0; i < nPtr->size(); i++) result.normals.push_back({(*nPtr)[i].x, (*nPtr)[i].y, (*nPtr)[i].z}); result.hasNormals = true; } } }
        { IV2fGeomParam p = schema.getUVsParam(); if (p.valid()) { IV2fGeomParam::Sample us; p.getExpanded(us, makeSelector(index)); auto uPtr = us.getVals(); if (uPtr && uPtr->size() > 0) { for (size_t i = 0; i < uPtr->size(); i++) result.uvs.push_back(fromV2f((*uPtr)[i])); result.hasUVs = true; } } }
        result.selfBounds = fromBox3d(sample.getSelfBounds());
        result.selfBoundsSet = sample.getSelfBounds().hasVolume();
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("polymesh_get: ") + e.what()); return -1; }
}
