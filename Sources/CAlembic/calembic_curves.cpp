#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicOCurves { OCurves curves; CAlembicOCurves(OObject p, const std::string& n) : curves(p, n) {} };
struct CAlembicICurves { ICurves curves; CAlembicICurves(IObject o) : curves(o, kWrapExisting) {} };

static CurveType toCT(CAlembicCurveType t) { switch(t){case CAlembicCurveType_Cubic:return kCubic;case CAlembicCurveType_Linear:return kLinear;default:return kVariableOrder;} }
static BasisType toBT(CAlembicBasisType t) { switch(t){case CAlembicBasisType_Bezier:return kBezierBasis;case CAlembicBasisType_BSpline:return kBsplineBasis;default:return kCatmullromBasis;} }
static CAlembicCurveType fCT(CurveType t){switch(t){case kCubic:return CAlembicCurveType_Cubic;case kLinear:return CAlembicCurveType_Linear;default:return CAlembicCurveType_VariableOrder;}}
static CAlembicBasisType fBT(BasisType t){switch(t){case kBezierBasis:return CAlembicBasisType_Bezier;case kBsplineBasis:return CAlembicBasisType_BSpline;default:return CAlembicBasisType_CatmullRom;}}

std::shared_ptr<CAlembicOCurves> calembic_create_curves(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOCurves>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_curves: ") + e.what()); return nullptr; }
}

int calembic_curves_set(const std::shared_ptr<CAlembicOCurves>& curves, const CAlembicCurvesSample& sample) {
    try {
        OCurvesSchema::Sample s; s.setType(toCT(sample.curveType)); s.setBasis(toBT(sample.basis)); s.setWrap(sample.wrap ? kPeriodic : kNonPeriodic);
        // Declare all temp vectors at outer scope so their data stays valid until schema.set(s).
        std::vector<Imath::V3f> pos, normals;
        std::vector<Imath::V2f> uvs;
        pos.reserve(sample.positions.size()); for (auto& p : sample.positions) pos.push_back(Imath::V3f(p.x,p.y,p.z));
        s.setPositions(V3fArraySample(pos.data(), pos.size()));
        s.setCurvesNumVertices(Int32ArraySample(sample.vertsPerCurve.data(), sample.vertsPerCurve.size()));
        if (sample.hasWidths && !sample.widths.empty()) s.setWidths(OFloatGeomParam::Sample(FloatArraySample(sample.widths.data(), sample.widths.size()), kVertexScope));
        if (sample.hasNormals && !sample.normals.empty()) { normals.reserve(sample.normals.size()); for (auto& v : sample.normals) normals.push_back(Imath::V3f(v.x,v.y,v.z)); s.setNormals(ON3fGeomParam::Sample(N3fArraySample(normals.data(), normals.size()), kVertexScope)); }
        if (sample.hasUVs && !sample.uvs.empty()) { uvs.reserve(sample.uvs.size()); for (auto& v : sample.uvs) uvs.push_back(toV2f(v)); s.setUVs(OV2fGeomParam::Sample(V2fArraySample(uvs.data(), uvs.size()), kVertexScope)); }
        if (sample.selfBoundsSet) s.setSelfBounds(toBox3d(sample.selfBounds));
        curves->curves.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("curves_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicICurves> calembic_object_as_curves(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicICurves>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_curves: ") + e.what()); return nullptr; }
}

uint32_t calembic_curves_num_samples(const std::shared_ptr<CAlembicICurves>& curves) {
    try { return static_cast<uint32_t>(curves->curves.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_curves_get(const std::shared_ptr<CAlembicICurves>& curves, uint32_t index, CAlembicCurvesSample* out) {
    try {
        ICurvesSchema::Sample sample; curves->curves.getSchema().get(sample, makeSelector(index));
        CAlembicCurvesSample result; result.curveType=fCT(sample.getType()); result.basis=fBT(sample.getBasis()); result.wrap=(sample.getWrap()==kPeriodic); result.selfBoundsSet=false;
        auto posPtr = sample.getPositions(); if (posPtr && posPtr->size() > 0) { for (size_t i=0; i<posPtr->size(); i++) result.positions.push_back(fromV3f((*posPtr)[i])); }
        auto nvPtr = sample.getCurvesNumVertices(); if (nvPtr) result.vertsPerCurve.assign(nvPtr->get(), nvPtr->get() + nvPtr->size());
        auto& sc = curves->curves.getSchema();
        { IFloatGeomParam p = sc.getWidthsParam(); if (p.valid()) { IFloatGeomParam::Sample ws; p.getExpanded(ws, makeSelector(index)); auto wPtr = ws.getVals(); if (wPtr && wPtr->size() > 0) { result.widths.assign(wPtr->get(), wPtr->get() + wPtr->size()); result.hasWidths = true; } } }
        { IN3fGeomParam p = sc.getNormalsParam(); if (p.valid()) { IN3fGeomParam::Sample ns; p.getExpanded(ns, makeSelector(index)); auto nPtr = ns.getVals(); if (nPtr && nPtr->size() > 0) { for (size_t i=0; i<nPtr->size(); i++) result.normals.push_back({(*nPtr)[i].x,(*nPtr)[i].y,(*nPtr)[i].z}); result.hasNormals = true; } } }
        { IV2fGeomParam p = sc.getUVsParam(); if (p.valid()) { IV2fGeomParam::Sample us; p.getExpanded(us, makeSelector(index)); auto uPtr = us.getVals(); if (uPtr && uPtr->size() > 0) { for (size_t i=0; i<uPtr->size(); i++) result.uvs.push_back(fromV2f((*uPtr)[i])); result.hasUVs = true; } } }
        if (sample.getSelfBounds().hasVolume()) { result.selfBounds = fromBox3d(sample.getSelfBounds()); result.selfBoundsSet = true; }
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("curves_get: ") + e.what()); return -1; }
}
