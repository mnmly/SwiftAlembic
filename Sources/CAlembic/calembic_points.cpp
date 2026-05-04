#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicOPoints { OPoints points; CAlembicOPoints(OObject p, const std::string& n) : points(p, n) {} };
struct CAlembicIPoints { IPoints points; CAlembicIPoints(IObject o) : points(o, kWrapExisting) {} };

std::shared_ptr<CAlembicOPoints> calembic_create_points(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOPoints>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_points: ") + e.what()); return nullptr; }
}

int calembic_points_set(const std::shared_ptr<CAlembicOPoints>& points, const CAlembicPointsSample& sample) {
    try {
        OPointsSchema::Sample s;
        std::vector<Imath::V3f> pos; pos.reserve(sample.positions.size()); for (auto& p : sample.positions) pos.push_back(Imath::V3f(p.x,p.y,p.z));
        s.setPositions(V3fArraySample(pos.data(), pos.size()));

        if (sample.hasIds && !sample.ids.empty()) {
            s.setIds(UInt64ArraySample(sample.ids.data(), sample.ids.size()));
        } else {
            // Auto-generate sequential IDs
            std::vector<uint64_t> ids(sample.positions.size());
            for (size_t i = 0; i < ids.size(); i++) ids[i] = i;
            s.setIds(UInt64ArraySample(ids.data(), ids.size()));
        }
        if (sample.hasWidths && !sample.widths.empty()) s.setWidths(OFloatGeomParam::Sample(FloatArraySample(sample.widths.data(), sample.widths.size()), kVertexScope));
        if (sample.hasVelocities && !sample.velocities.empty()) { std::vector<Imath::V3f> vel; for (auto& v : sample.velocities) vel.push_back(Imath::V3f(v.x,v.y,v.z)); s.setVelocities(V3fArraySample(vel.data(), vel.size())); }
        if (sample.selfBoundsSet) s.setSelfBounds(toBox3d(sample.selfBounds));
        points->points.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("points_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicIPoints> calembic_object_as_points(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicIPoints>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_points: ") + e.what()); return nullptr; }
}

uint32_t calembic_points_num_samples(const std::shared_ptr<CAlembicIPoints>& points) {
    try { return static_cast<uint32_t>(points->points.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_points_get(const std::shared_ptr<CAlembicIPoints>& points, uint32_t index, CAlembicPointsSample* out) {
    try {
        IPointsSchema::Sample sample; points->points.getSchema().get(sample, makeSelector(index));
        CAlembicPointsSample result; result.selfBoundsSet = false;
        auto posPtr = sample.getPositions(); if (posPtr && posPtr->size() > 0) { for (size_t i=0; i<posPtr->size(); i++) result.positions.push_back(fromV3f((*posPtr)[i])); }
        auto idPtr = sample.getIds(); if (idPtr && idPtr->size() > 0) { result.ids.assign(idPtr->get(), idPtr->get() + idPtr->size()); result.hasIds = true; }
        { auto& sc = points->points.getSchema(); IFloatGeomParam p = sc.getWidthsParam(); if (p.valid()) { IFloatGeomParam::Sample ws; p.getExpanded(ws, makeSelector(index)); auto wPtr = ws.getVals(); if (wPtr && wPtr->size() > 0) { result.widths.assign(wPtr->get(), wPtr->get() + wPtr->size()); result.hasWidths = true; } } }
        auto velPtr = sample.getVelocities(); if (velPtr && velPtr->size() > 0) { for (size_t i=0; i<velPtr->size(); i++) result.velocities.push_back(fromV3f((*velPtr)[i])); result.hasVelocities = true; }
        if (sample.getSelfBounds().hasVolume()) { result.selfBounds = fromBox3d(sample.getSelfBounds()); result.selfBoundsSet = true; }
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("points_get: ") + e.what()); return -1; }
}
