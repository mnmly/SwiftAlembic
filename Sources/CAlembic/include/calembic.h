#ifndef CALEMBIC_H
#define CALEMBIC_H

#include "calembic_types.h"

#include <memory>
#include <string>
#include <vector>
#include <optional>

// --- Forward declarations for implementation types ---

struct CAlembicOArchive;
struct CAlembicIArchive;
struct CAlembicOObject;
struct CAlembicIObject;
struct CAlembicOPolyMesh;
struct CAlembicIPolyMesh;
struct CAlembicOSubD;
struct CAlembicISubD;
struct CAlembicOCurves;
struct CAlembicICurves;
struct CAlembicOPoints;
struct CAlembicIPoints;
struct CAlembicONuPatch;
struct CAlembicINuPatch;
struct CAlembicOXform;
struct CAlembicIXform;
struct CAlembicOCamera;
struct CAlembicICamera;
struct CAlembicOLight;
struct CAlembicILight;
struct CAlembicOFaceSet;
struct CAlembicIFaceSet;

// --- Archive ---

std::shared_ptr<CAlembicOArchive> calembic_create_archive(const std::string& path);
std::shared_ptr<CAlembicIArchive> calembic_open_archive(const std::string& path);

// --- Object hierarchy ---

std::shared_ptr<CAlembicOObject> calembic_archive_top_O(std::shared_ptr<CAlembicOArchive> archive);
std::shared_ptr<CAlembicIObject> calembic_archive_top_I(std::shared_ptr<CAlembicIArchive> archive);

std::shared_ptr<CAlembicOObject> calembic_create_child(std::shared_ptr<CAlembicOObject> parent,
                                                        const std::string& name);

std::string calembic_object_name(const std::shared_ptr<CAlembicIObject>& obj);
std::string calembic_object_full_name(const std::shared_ptr<CAlembicIObject>& obj);
std::vector<std::shared_ptr<CAlembicIObject>> calembic_object_children(
    const std::shared_ptr<CAlembicIObject>& obj);

// --- Schema type queries ---

typedef enum {
    CAlembicSchema_Unknown = 0,
    CAlembicSchema_PolyMesh,
    CAlembicSchema_SubD,
    CAlembicSchema_Curves,
    CAlembicSchema_Points,
    CAlembicSchema_NuPatch,
    CAlembicSchema_Xform,
    CAlembicSchema_Camera,
    CAlembicSchema_Light,
    CAlembicSchema_FaceSet
} CAlembicSchemaType;

CAlembicSchemaType calembic_object_schema_type(const std::shared_ptr<CAlembicIObject>& obj);

// --- PolyMesh write/read ---

std::shared_ptr<CAlembicOPolyMesh> calembic_create_polymesh(std::shared_ptr<CAlembicOObject> parent,
                                                              const std::string& name);
int calembic_polymesh_set(const std::shared_ptr<CAlembicOPolyMesh>& mesh,
                          const CAlembicPolyMeshSample& sample);

std::shared_ptr<CAlembicIPolyMesh> calembic_object_as_polymesh(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_polymesh_num_samples(const std::shared_ptr<CAlembicIPolyMesh>& mesh);
int calembic_polymesh_get(const std::shared_ptr<CAlembicIPolyMesh>& mesh,
                          uint32_t index, CAlembicPolyMeshSample* out);

// --- SubD write/read ---

std::shared_ptr<CAlembicOSubD> calembic_create_subd(std::shared_ptr<CAlembicOObject> parent,
                                                      const std::string& name);
int calembic_subd_set(const std::shared_ptr<CAlembicOSubD>& subd,
                      const CAlembicSubDSample& sample);

std::shared_ptr<CAlembicISubD> calembic_object_as_subd(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_subd_num_samples(const std::shared_ptr<CAlembicISubD>& subd);
int calembic_subd_get(const std::shared_ptr<CAlembicISubD>& subd,
                      uint32_t index, CAlembicSubDSample* out);

// --- Curves write/read ---

std::shared_ptr<CAlembicOCurves> calembic_create_curves(std::shared_ptr<CAlembicOObject> parent,
                                                          const std::string& name);
int calembic_curves_set(const std::shared_ptr<CAlembicOCurves>& curves,
                        const CAlembicCurvesSample& sample);

std::shared_ptr<CAlembicICurves> calembic_object_as_curves(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_curves_num_samples(const std::shared_ptr<CAlembicICurves>& curves);
int calembic_curves_get(
    const std::shared_ptr<CAlembicICurves>& curves, uint32_t index,
    CAlembicCurvesSample* out);

// --- Points write/read ---

std::shared_ptr<CAlembicOPoints> calembic_create_points(std::shared_ptr<CAlembicOObject> parent,
                                                          const std::string& name);
int calembic_points_set(const std::shared_ptr<CAlembicOPoints>& points,
                        const CAlembicPointsSample& sample);

std::shared_ptr<CAlembicIPoints> calembic_object_as_points(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_points_num_samples(const std::shared_ptr<CAlembicIPoints>& points);
int calembic_points_get(
    const std::shared_ptr<CAlembicIPoints>& points, uint32_t index,
    CAlembicPointsSample* out);

// --- NuPatch write/read ---

std::shared_ptr<CAlembicONuPatch> calembic_create_nupatch(std::shared_ptr<CAlembicOObject> parent,
                                                            const std::string& name);
int calembic_nupatch_set(const std::shared_ptr<CAlembicONuPatch>& nupatch,
                         const CAlembicNuPatchSample& sample);

std::shared_ptr<CAlembicINuPatch> calembic_object_as_nupatch(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_nupatch_num_samples(const std::shared_ptr<CAlembicINuPatch>& nupatch);
int calembic_nupatch_get(
    const std::shared_ptr<CAlembicINuPatch>& nupatch, uint32_t index,
    CAlembicNuPatchSample* out);

// --- Xform write/read ---

std::shared_ptr<CAlembicOXform> calembic_create_xform(std::shared_ptr<CAlembicOObject> parent,
                                                        const std::string& name);
int calembic_xform_set(const std::shared_ptr<CAlembicOXform>& xform,
                       const CAlembicXformSample& sample);

std::shared_ptr<CAlembicIXform> calembic_object_as_xform(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_xform_num_samples(const std::shared_ptr<CAlembicIXform>& xform);
int calembic_xform_get(
    const std::shared_ptr<CAlembicIXform>& xform, uint32_t index,
    CAlembicXformSample* out);

// --- Camera write/read ---

std::shared_ptr<CAlembicOCamera> calembic_create_camera(std::shared_ptr<CAlembicOObject> parent,
                                                          const std::string& name);
int calembic_camera_set(const std::shared_ptr<CAlembicOCamera>& camera,
                        const CAlembicCameraSample& sample);

std::shared_ptr<CAlembicICamera> calembic_object_as_camera(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_camera_num_samples(const std::shared_ptr<CAlembicICamera>& camera);
int calembic_camera_get(
    const std::shared_ptr<CAlembicICamera>& camera, uint32_t index,
    CAlembicCameraSample* out);

// --- Light write/read ---

std::shared_ptr<CAlembicOLight> calembic_create_light(std::shared_ptr<CAlembicOObject> parent,
                                                        const std::string& name);
int calembic_light_set(const std::shared_ptr<CAlembicOLight>& light,
                       const CAlembicLightSample& sample);

std::shared_ptr<CAlembicILight> calembic_object_as_light(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_light_num_samples(const std::shared_ptr<CAlembicILight>& light);
int calembic_light_get(
    const std::shared_ptr<CAlembicILight>& light, uint32_t index,
    CAlembicLightSample* out);

// --- FaceSet write/read ---

std::shared_ptr<CAlembicOFaceSet> calembic_create_faceset(std::shared_ptr<CAlembicOObject> parent,
                                                            const std::string& name);
int calembic_faceset_set(const std::shared_ptr<CAlembicOFaceSet>& faceset,
                         const CAlembicFaceSetSample& sample);

std::shared_ptr<CAlembicIFaceSet> calembic_object_as_faceset(
    const std::shared_ptr<CAlembicIObject>& obj);
uint32_t calembic_faceset_num_samples(const std::shared_ptr<CAlembicIFaceSet>& faceset);
int calembic_faceset_get(
    const std::shared_ptr<CAlembicIFaceSet>& faceset, uint32_t index,
    CAlembicFaceSetSample* out);

// --- Error handling ---

const char* calembic_last_error();
CAlembicError calembic_last_error_code();

// --- Convenience type aliases for Swift ---

using AlembicOArchivePtr = std::shared_ptr<CAlembicOArchive>;
using AlembicIArchivePtr = std::shared_ptr<CAlembicIArchive>;
using AlembicOObjectPtr = std::shared_ptr<CAlembicOObject>;
using AlembicIObjectPtr = std::shared_ptr<CAlembicIObject>;
using AlembicOPolyMeshPtr = std::shared_ptr<CAlembicOPolyMesh>;
using AlembicIPolyMeshPtr = std::shared_ptr<CAlembicIPolyMesh>;
using AlembicOSubDPtr = std::shared_ptr<CAlembicOSubD>;
using AlembicISubDPtr = std::shared_ptr<CAlembicISubD>;
using AlembicOCurvesPtr = std::shared_ptr<CAlembicOCurves>;
using AlembicICurvesPtr = std::shared_ptr<CAlembicICurves>;
using AlembicOPointsPtr = std::shared_ptr<CAlembicOPoints>;
using AlembicIPointsPtr = std::shared_ptr<CAlembicIPoints>;
using AlembicONuPatchPtr = std::shared_ptr<CAlembicONuPatch>;
using AlembicINuPatchPtr = std::shared_ptr<CAlembicINuPatch>;
using AlembicOXformPtr = std::shared_ptr<CAlembicOXform>;
using AlembicIXformPtr = std::shared_ptr<CAlembicIXform>;
using AlembicOCameraPtr = std::shared_ptr<CAlembicOCamera>;
using AlembicICameraPtr = std::shared_ptr<CAlembicICamera>;
using AlembicOLightPtr = std::shared_ptr<CAlembicOLight>;
using AlembicILightPtr = std::shared_ptr<CAlembicILight>;
using AlembicOFaceSetPtr = std::shared_ptr<CAlembicOFaceSet>;
using AlembicIFaceSetPtr = std::shared_ptr<CAlembicIFaceSet>;

using AlembicIObjectVector = std::vector<std::shared_ptr<CAlembicIObject>>;

#endif // CALEMBIC_H
