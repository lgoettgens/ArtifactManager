#
# ArtifactManager: Download and manage additional data files for your GAP package
#
#! @Chapter Manifest API

#! @Description
#!   Return the validated metadata record for <A>name</A>.
DeclareGlobalFunction( "ArtifactMetadata" );

#! @Description
#!   Return the canonical extracted-tree SHA-256 hash for <A>name</A>.
DeclareGlobalFunction( "ArtifactHash" );

#! @Description
#!   Return the validated artifacts declared by the package.
DeclareGlobalFunction( "ListArtifacts" );

DeclareGlobalFunction( "ArtifactManager_Error" );
DeclareGlobalFunction( "ArtifactManager_ManifestFilename" );
DeclareGlobalFunction( "ArtifactManager_ReadManifest" );
DeclareGlobalFunction( "ArtifactManager_ValidateManifest" );
DeclareGlobalFunction( "ArtifactManager_ResolveArtifact" );
