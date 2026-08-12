gap> START_TEST( "manifest.tst" );

# Exercise the public package-name API against a real package-shaped fixture.
# This catches regressions where the manifest reader accidentally accepts only
# raw Artifacts.g filenames instead of resolving them through GAP's package
# directory machinery.
gap> testpackagepath := DirectoriesPackageLibrary("ArtifactManager", "tst/fixtures/pkg/TestPackage")[1];;
gap> testpkgname := "TestPackage";;
gap> Unbind(GAPInfo.PackagesInfo.(testpkgname));;
gap> Unbind(GAPInfo.PackagesLoaded.(testpkgname));;
gap> SetPackagePath(testpkgname, testpackagepath);
gap> artifacts := ListArtifacts( testpkgname );;
gap> Length( artifacts );
2
gap> artifacts[ 1 ].name;
"brent-table-1000"
gap> artifacts[ 2 ].lazy;
true
gap> Length( artifacts[ 1 ].downloads );
2
gap> ArtifactMetadata( testpkgname, "brent-table-1000" ).downloads[ 2 ].url;
"https://mirror.example.org/data/brent-table-1000.tar.gz"
gap> ArtifactHash( testpkgname, "brent-table-2000" );
"1111111111111111111111111111111111111111111111111111111111111111"

# Missing artifacts should be reported in terms of the client package name,
# because callers do not pass or usually know the resolved manifest filename.
gap> ArtifactMetadata( testpkgname, "does-not-exist" );
Error, ArtifactManager: TestPackage: artifact 'does-not-exist' is not declared

# The remaining checks call the lower-level manifest reader and validator
# directly. They keep schema failures focused on the fixture filename while the
# public API stays package-oriented.
gap> invalidManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "invalid-tree-sha256.g" );;
gap> ArtifactManager_ValidateManifest( invalidManifest, ArtifactManager_ReadManifest( invalidManifest ) );
Error, ArtifactManager: ./tst/fixtures/invalid-tree-sha256.g: artifact 'bad' h\
as an invalid 'tree_sha256'
gap> missingLazyManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "missing-lazy.g" );;
gap> ArtifactManager_ValidateManifest( missingLazyManifest, ArtifactManager_ReadManifest( missingLazyManifest ) );
Error, ArtifactManager: ./tst/fixtures/missing-lazy.g: artifact 'm' is missing\
 'lazy'
gap> falseLazyManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "false-lazy.g" );;
gap> ArtifactManager_ValidateManifest( falseLazyManifest, ArtifactManager_ReadManifest( falseLazyManifest ) );
Error, ArtifactManager: ./tst/fixtures/false-lazy.g: artifact 'f' has invalid \
'lazy' (currently only 'true' is supported)
gap> missingURLManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "missing-url.g" );;
gap> ArtifactManager_ValidateManifest( missingURLManifest, ArtifactManager_ReadManifest( missingURLManifest ) );
Error, ArtifactManager: ./tst/fixtures/missing-url.g: artifact 'u', download #\
1 is missing 'url'
gap> missingSHA256Manifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "missing-sha256.g" );;
gap> ArtifactManager_ValidateManifest( missingSHA256Manifest, ArtifactManager_ReadManifest( missingSHA256Manifest ) );
Error, ArtifactManager: ./tst/fixtures/missing-sha256.g: artifact 's', downloa\
d #1 is missing 'sha256'
gap> STOP_TEST( "manifest.tst", 1 );
