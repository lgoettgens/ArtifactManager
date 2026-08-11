#
# ArtifactManager: Download and manage additional data files for your GAP package
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
LoadPackage( "ArtifactManager" );

TestDirectory(DirectoriesPackageLibrary( "ArtifactManager", "tst" ),
  rec(exitGAP := true));

FORCE_QUIT_GAP(1); # if we ever get here, there was an error
