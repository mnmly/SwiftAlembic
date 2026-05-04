#ifndef CALEMBIC_TYPES_H
#define CALEMBIC_TYPES_H

#include <cstdint>
#include <string>
#include <vector>
#include <memory>
#include <array>

// --- Imath-compatible geometric types ---

typedef struct { float x, y; } CAlembicV2f;
typedef struct { double x, y; } CAlembicV2d;
typedef struct { float x, y, z; } CAlembicV3f;
typedef struct { double x, y, z; } CAlembicV3d;
typedef struct { float r, g, b, a; } CAlembicC4f;
typedef struct { float r, i, j, k; } CAlembicQuatf;
typedef struct { double r, i, j, k; } CAlembicQuatd;
typedef struct { float x, y, z; } CAlembicN3f;
typedef struct { CAlembicV3d min; CAlembicV3d max; } CAlembicBox3d;
typedef struct { double m[4][4]; } CAlembicM44d;

// --- Xform operation ---

typedef enum {
    CAlembicXformOp_Translate = 0,
    CAlembicXformOp_Rotate,
    CAlembicXformOp_Scale,
    CAlembicXformOp_Matrix
} CAlembicXformOpType;

typedef struct {
    CAlembicXformOpType type;
    std::array<double, 16> values;
    int valueCount;
} CAlembicXformOp;

// --- Curve types ---

typedef enum {
    CAlembicCurveType_Cubic = 0,
    CAlembicCurveType_Linear,
    CAlembicCurveType_VariableOrder
} CAlembicCurveType;

typedef enum {
    CAlembicBasisType_Bezier = 0,
    CAlembicBasisType_BSpline,
    CAlembicBasisType_CatmullRom
} CAlembicBasisType;

// --- Geometry scope ---

typedef enum {
    CAlembicGeometryScope_Constant = 0,
    CAlembicGeometryScope_Uniform,
    CAlembicGeometryScope_Varying,
    CAlembicGeometryScope_Vertex,
    CAlembicGeometryScope_FaceVarying
} CAlembicGeometryScope;

// --- Light type ---

typedef enum {
    CAlembicLightType_Point = 0,
    CAlembicLightType_Distant,
    CAlembicLightType_Spot,
    CAlembicLightType_Area
} CAlembicLightType;

// --- Error codes ---

typedef enum {
    CAlembicError_OK = 0,
    CAlembicError_FileNotFound = -1,
    CAlembicError_AlreadyOpen = -2,
    CAlembicError_InvalidSchema = -3,
    CAlembicError_InvalidSample = -4,
    CAlembicError_Internal = -5
} CAlembicError;

// --- Sample data types ---

struct CAlembicPolyMeshSample {
    std::vector<CAlembicV3f> positions;
    std::vector<int32_t> faceIndices;
    std::vector<int32_t> faceCounts;
    std::vector<CAlembicN3f> normals;   bool hasNormals = false;
    std::vector<CAlembicV2f> uvs;       bool hasUVs = false;
    std::vector<CAlembicV3f> velocities; bool hasVelocities = false;
    bool selfBoundsSet = false;
    CAlembicBox3d selfBounds;
};

struct CAlembicSubDSample {
    std::vector<CAlembicV3f> positions;
    std::vector<int32_t> faceIndices;
    std::vector<int32_t> faceCounts;
    std::vector<int32_t> creaseIndices;      bool hasCreaseIndices = false;
    std::vector<int32_t> creaseLengths;      bool hasCreaseLengths = false;
    std::vector<float> creaseSharpnesses;    bool hasCreaseSharpnesses = false;
    std::vector<int32_t> cornerIndices;      bool hasCornerIndices = false;
    std::vector<float> cornerSharpnesses;    bool hasCornerSharpnesses = false;
    std::vector<float> holes;                bool hasHoles = false;
    CAlembicGeometryScope interpolation = CAlembicGeometryScope_Vertex;
};

struct CAlembicCurvesSample {
    std::vector<CAlembicV3f> positions;
    std::vector<int32_t> vertsPerCurve;
    std::vector<float> widths;             bool hasWidths = false;
    std::vector<CAlembicN3f> normals;      bool hasNormals = false;
    std::vector<CAlembicV2f> uvs;          bool hasUVs = false;
    CAlembicCurveType curveType = CAlembicCurveType_Cubic;
    CAlembicBasisType basis = CAlembicBasisType_Bezier;
    bool wrap = false;
    CAlembicBox3d selfBounds;
    bool selfBoundsSet = false;
};

struct CAlembicPointsSample {
    std::vector<CAlembicV3f> positions;
    std::vector<uint64_t> ids;             bool hasIds = false;
    std::vector<float> widths;             bool hasWidths = false;
    std::vector<CAlembicV3f> velocities;   bool hasVelocities = false;
    CAlembicBox3d selfBounds;
    bool selfBoundsSet = false;
};

struct CAlembicNuPatchSample {
    int32_t uOrder = 0;
    int32_t vOrder = 0;
    std::vector<float> uKnot;
    std::vector<float> vKnot;
    std::vector<CAlembicV3f> positions;
    std::vector<float> positionWeights;    bool hasPositionWeights = false;
    std::vector<CAlembicN3f> normals;      bool hasNormals = false;
    std::vector<CAlembicV2f> uvs;          bool hasUVs = false;
    CAlembicBox3d selfBounds;
    bool selfBoundsSet = false;
};

struct CAlembicXformSample {
    std::vector<CAlembicXformOp> ops;
    bool inherits = true;
};

struct CAlembicCameraSample {
    double focalLength = 35;
    double horizontalAperture = 36;
    double verticalAperture = 24;
    double horizontalFilmOffset = 0;
    double verticalFilmOffset = 0;
    double fStop = 5.6;
    double focusDistance = 1;
    double lensSqueezeRatio = 1;
    double overScanLeft = 0;
    double overScanRight = 0;
    double overScanTop = 0;
    double overScanBottom = 0;
    double shutterOpen = 0;
    double shutterClose = 0.020833333333333332;
    CAlembicBox3d childBounds;             bool hasChildBounds = false;
    CAlembicBox3d selfBounds;
    bool selfBoundsSet = false;
};

struct CAlembicLightSample {
    CAlembicBox3d selfBounds;
    bool selfBoundsSet = false;
};

struct CAlembicFaceSetSample {
    std::vector<int32_t> faceIndices;
    CAlembicBox3d selfBounds;
    bool selfBoundsSet = false;
};

#endif // CALEMBIC_TYPES_H
