#include "calembic_shared.h"
using namespace Alembic::Abc; using namespace Alembic::AbcGeom;

struct CAlembicOCamera { OCamera camera; CAlembicOCamera(OObject p, const std::string& n) : camera(p, n) {} };
struct CAlembicICamera { ICamera camera; CAlembicICamera(IObject o) : camera(o, kWrapExisting) {} };

std::shared_ptr<CAlembicOCamera> calembic_create_camera(std::shared_ptr<CAlembicOObject> parent, const std::string& name) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicOCamera>(parent->object, name); }
    catch (const std::exception& e) { set_error(CAlembicError_Internal, std::string("create_camera: ") + e.what()); return nullptr; }
}

int calembic_camera_set(const std::shared_ptr<CAlembicOCamera>& camera, const CAlembicCameraSample& sample) {
    try {
        CameraSample s;
        s.setFocalLength(sample.focalLength); s.setHorizontalAperture(sample.horizontalAperture);
        s.setVerticalAperture(sample.verticalAperture); s.setHorizontalFilmOffset(sample.horizontalFilmOffset);
        s.setVerticalFilmOffset(sample.verticalFilmOffset); s.setFStop(sample.fStop);
        s.setFocusDistance(sample.focusDistance); s.setLensSqueezeRatio(sample.lensSqueezeRatio);
        s.setOverScanTop(sample.overScanTop); s.setOverScanBottom(sample.overScanBottom);
        s.setOverScanLeft(sample.overScanLeft); s.setOverScanRight(sample.overScanRight);
        s.setShutterOpen(sample.shutterOpen); s.setShutterClose(sample.shutterClose);
        if (sample.hasChildBounds) s.setChildBounds(toBox3d(sample.childBounds));
        camera->camera.getSchema().set(s);
        set_error(CAlembicError_OK, ""); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("camera_set: ") + e.what()); return -1; }
}

std::shared_ptr<CAlembicICamera> calembic_object_as_camera(const std::shared_ptr<CAlembicIObject>& obj) {
    try { set_error(CAlembicError_OK, ""); return std::make_shared<CAlembicICamera>(obj->object); }
    catch (const std::exception& e) { set_error(CAlembicError_InvalidSchema, std::string("as_camera: ") + e.what()); return nullptr; }
}

uint32_t calembic_camera_num_samples(const std::shared_ptr<CAlembicICamera>& camera) {
    try { return static_cast<uint32_t>(camera->camera.getSchema().getNumSamples()); } catch (...) { return 0; }
}

int calembic_camera_get(const std::shared_ptr<CAlembicICamera>& camera, uint32_t index, CAlembicCameraSample* out) {
    try {
        CameraSample sample; camera->camera.getSchema().get(sample, makeSelector(index));
        CAlembicCameraSample result;
        result.focalLength=sample.getFocalLength(); result.horizontalAperture=sample.getHorizontalAperture();
        result.verticalAperture=sample.getVerticalAperture(); result.horizontalFilmOffset=sample.getHorizontalFilmOffset();
        result.verticalFilmOffset=sample.getVerticalFilmOffset(); result.fStop=sample.getFStop();
        result.focusDistance=sample.getFocusDistance(); result.lensSqueezeRatio=sample.getLensSqueezeRatio();
        result.overScanTop=sample.getOverScanTop(); result.overScanBottom=sample.getOverScanBottom();
        result.overScanLeft=sample.getOverScanLeft(); result.overScanRight=sample.getOverScanRight();
        result.shutterOpen=sample.getShutterOpen(); result.shutterClose=sample.getShutterClose();
        auto b = sample.getChildBounds();
        if (b.hasVolume()) { result.childBounds = CAlembicBox3d{{b.min.x,b.min.y,b.min.z},{b.max.x,b.max.y,b.max.z}}; result.hasChildBounds=true; }
        result.selfBoundsSet = false;
        set_error(CAlembicError_OK, ""); *out = std::move(result); return 0;
    } catch (const std::exception& e) { set_error(CAlembicError_InvalidSample, std::string("camera_get: ") + e.what()); return -1; }
}
