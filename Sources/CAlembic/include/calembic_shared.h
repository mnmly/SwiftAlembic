#ifndef CALEMBIC_SHARED_H
#define CALEMBIC_SHARED_H

#include "calembic_internal.h"

#include <Alembic/Abc/All.h>
#include <Alembic/AbcCoreOgawa/All.h>
#include <Alembic/AbcCoreFactory/All.h>
#include <Alembic/AbcGeom/All.h>

#include <stdexcept>
#include <cstring>

// === Object definitions (shared across schema .cpp files) ===

struct CAlembicOArchive {
    Alembic::Abc::OArchive archive;
    CAlembicOArchive(const std::string& path)
        : archive(Alembic::AbcCoreOgawa::WriteArchive(), path,
                  Alembic::Abc::MetaData()) {}
};

struct CAlembicIArchive {
    Alembic::Abc::IArchive archive;
    CAlembicIArchive(Alembic::Abc::IArchive a) : archive(std::move(a)) {}
};

struct CAlembicOObject {
    Alembic::Abc::OObject object;
    CAlembicOObject(Alembic::Abc::OObject o) : object(std::move(o)) {}
};

struct CAlembicIObject {
    Alembic::Abc::IObject object;
    CAlembicIObject(Alembic::Abc::IObject o) : object(std::move(o)) {}
};

// === Conversion helpers ===

inline Imath::V3f toV3f(const CAlembicV3f& v) { return {v.x, v.y, v.z}; }
inline Imath::V2f toV2f(const CAlembicV2f& v) { return {v.x, v.y}; }
inline Imath::V3d toV3d(const CAlembicV3d& v) { return {v.x, v.y, v.z}; }

inline CAlembicV3f fromV3f(const Imath::V3f& v) { return {v.x, v.y, v.z}; }
inline CAlembicV2f fromV2f(const Imath::V2f& v) { return {v.x, v.y}; }
inline CAlembicV3d fromV3d(const Imath::V3d& v) { return {v.x, v.y, v.z}; }

inline CAlembicBox3d fromBox3d(const Imath::Box3d& b) {
    return {{b.min.x, b.min.y, b.min.z}, {b.max.x, b.max.y, b.max.z}};
}

inline Imath::Box3d toBox3d(const CAlembicBox3d& b) {
    Imath::Box3d r;
    r.min = Imath::V3d(b.min.x, b.min.y, b.min.z);
    r.max = Imath::V3d(b.max.x, b.max.y, b.max.z);
    return r;
}

// === ISampleSelector helper ===

inline Alembic::Abc::ISampleSelector makeSelector(uint32_t index) {
    return Alembic::Abc::ISampleSelector(static_cast<Alembic::Abc::index_t>(index));
}

#endif
