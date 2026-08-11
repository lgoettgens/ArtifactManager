gap> START_TEST( "manifest.tst" );
gap> manifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "valid-artifacts.g" );;
gap> artifacts := ListArtifacts( manifest );;
gap> Length( artifacts );
2
gap> artifacts[ 1 ].name;
"brent-table-1000"
gap> artifacts[ 2 ].lazy;
true
gap> Length( artifacts[ 1 ].downloads );
2
gap> ArtifactMetadata( "brent-table-1000", manifest ).downloads[ 2 ].url;
"https://mirror.example.org/data/brent-table-1000.tar.gz"
gap> ArtifactHash( "brent-table-2000", manifest );
"1111111111111111111111111111111111111111111111111111111111111111"
gap> invalidManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "invalid-tree-sha256.g" );;
gap> ListArtifacts( invalidManifest );
Error, ArtifactManager: ./tst/fixtures/invalid-tree-sha256.g: artifact 'bad' h\
as an invalid 'tree_sha256'
gap> missingLazyManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "missing-lazy.g" );;
gap> ListArtifacts( missingLazyManifest );
Error, ArtifactManager: ./tst/fixtures/missing-lazy.g: artifact 'm' is missing\
 'lazy'
gap> falseLazyManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "false-lazy.g" );;
gap> ListArtifacts( falseLazyManifest );
Error, ArtifactManager: ./tst/fixtures/false-lazy.g: artifact 'f' has invalid \
'lazy' (currently only 'true' is supported)
gap> missingURLManifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "missing-url.g" );;
gap> ListArtifacts( missingURLManifest );
Error, ArtifactManager: ./tst/fixtures/missing-url.g: artifact 'u', download #\
1 is missing 'url'
gap> missingSHA256Manifest := Filename( DirectoriesPackageLibrary( "ArtifactManager", "tst/fixtures" ), "missing-sha256.g" );;
gap> ListArtifacts( missingSHA256Manifest );
Error, ArtifactManager: ./tst/fixtures/missing-sha256.g: artifact 's', downloa\
d #1 is missing 'sha256'
gap> STOP_TEST( "manifest.tst", 1 );
