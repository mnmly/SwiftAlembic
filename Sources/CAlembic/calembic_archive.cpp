#include "calembic_shared.h"

using namespace Alembic::Abc;
using namespace Alembic::AbcGeom;

// === Archive ===

std::shared_ptr<CAlembicOArchive> calembic_create_archive(const std::string& path) {
    try {
        set_error(CAlembicError_OK, "");
        return std::make_shared<CAlembicOArchive>(path);
    } catch (const std::exception& e) {
        set_error(CAlembicError_FileNotFound, std::string("calembic_create_archive: ") + e.what());
        return nullptr;
    }
}

std::shared_ptr<CAlembicIArchive> calembic_open_archive(const std::string& path) {
    try {
        Alembic::AbcCoreFactory::IFactory factory;
        factory.setPolicy(ErrorHandler::kThrowPolicy);
        IArchive archive = factory.getArchive(path);
        if (!archive.valid()) {
            set_error(CAlembicError_FileNotFound, "could not open " + path);
            return nullptr;
        }
        set_error(CAlembicError_OK, "");
        return std::make_shared<CAlembicIArchive>(std::move(archive));
    } catch (const std::exception& e) {
        set_error(CAlembicError_FileNotFound, std::string("calembic_open_archive: ") + e.what());
        return nullptr;
    }
}

// === Object hierarchy ===

std::shared_ptr<CAlembicOObject> calembic_archive_top_O(std::shared_ptr<CAlembicOArchive> archive) {
    try {
        set_error(CAlembicError_OK, "");
        return std::make_shared<CAlembicOObject>(archive->archive.getTop());
    } catch (const std::exception& e) {
        set_error(CAlembicError_Internal, std::string("archive_top_O: ") + e.what());
        return nullptr;
    }
}

std::shared_ptr<CAlembicIObject> calembic_archive_top_I(std::shared_ptr<CAlembicIArchive> archive) {
    try {
        set_error(CAlembicError_OK, "");
        return std::make_shared<CAlembicIObject>(archive->archive.getTop());
    } catch (const std::exception& e) {
        set_error(CAlembicError_Internal, std::string("archive_top_I: ") + e.what());
        return nullptr;
    }
}

std::shared_ptr<CAlembicOObject> calembic_create_child(std::shared_ptr<CAlembicOObject> parent,
                                                        const std::string& name) {
    try {
        set_error(CAlembicError_OK, "");
        return std::make_shared<CAlembicOObject>(OObject(parent->object, name));
    } catch (const std::exception& e) {
        set_error(CAlembicError_Internal, std::string("create_child: ") + e.what());
        return nullptr;
    }
}

std::string calembic_object_name(const std::shared_ptr<CAlembicIObject>& obj) {
    try {
        return obj->object.getName();
    } catch (...) {
        set_error(CAlembicError_Internal, "object_name exception");
        return {};
    }
}

std::string calembic_object_full_name(const std::shared_ptr<CAlembicIObject>& obj) {
    try {
        return obj->object.getFullName();
    } catch (...) {
        set_error(CAlembicError_Internal, "object_full_name exception");
        return {};
    }
}

std::vector<std::shared_ptr<CAlembicIObject>> calembic_object_children(
    const std::shared_ptr<CAlembicIObject>& obj) {
    try {
        std::vector<std::shared_ptr<CAlembicIObject>> children;
        for (size_t i = 0; i < obj->object.getNumChildren(); i++) {
            children.push_back(std::make_shared<CAlembicIObject>(obj->object.getChild(i)));
        }
        set_error(CAlembicError_OK, "");
        return children;
    } catch (const std::exception& e) {
        set_error(CAlembicError_Internal, std::string("object_children: ") + e.what());
        return {};
    }
}

// === Schema type queries ===

CAlembicSchemaType calembic_object_schema_type(const std::shared_ptr<CAlembicIObject>& obj) {
    try {
        auto& md = obj->object.getMetaData();
        if (IPolyMesh::matches(md))  return CAlembicSchema_PolyMesh;
        if (ISubD::matches(md))      return CAlembicSchema_SubD;
        if (ICurves::matches(md))    return CAlembicSchema_Curves;
        if (IPoints::matches(md))    return CAlembicSchema_Points;
        if (INuPatch::matches(md))   return CAlembicSchema_NuPatch;
        if (IXform::matches(md))     return CAlembicSchema_Xform;
        if (ICamera::matches(md))    return CAlembicSchema_Camera;
        if (ILight::matches(md))     return CAlembicSchema_Light;
        if (IFaceSet::matches(md))   return CAlembicSchema_FaceSet;
        return CAlembicSchema_Unknown;
    } catch (...) {
        return CAlembicSchema_Unknown;
    }
}
