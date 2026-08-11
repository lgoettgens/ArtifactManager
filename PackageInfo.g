#
# ArtifactManager: Download and manage additional data files for your GAP package
#
# This file contains package meta data. For additional information on
# the meaning and correct usage of these fields, please consult the
# manual of the "Example" package as well as the comments in its
# PackageInfo.g file.
#
SetPackageInfo( rec(

PackageName := "ArtifactManager",
Subtitle := "Download and manage additional data files for your GAP package",
Version := "0.1",
Date := "11/08/2026", # dd/mm/yyyy format
License := "GPL-2.0-or-later",

Persons := [
  rec(
    FirstNames := "Lars",
    LastName := "Göttgens",
    WWWHome := "https://lgoe.li/",
    Email := "goettgens@art.rwth-aachen.de",
    IsAuthor := true,
    IsMaintainer := true,
    PostalAddress := "Lehrstuhl für Algebra und Darstellungstheorie",
    Place := "Aachen, Germany",
    Institution := "RWTH Aachen University",
  ),
],

SourceRepository := rec(
    Type := "git",
    URL := "https://github.com/lgoettgens/ArtifactManager",
),
IssueTrackerURL := Concatenation( ~.SourceRepository.URL, "/issues" ),
PackageWWWHome  := "https://lgoettgens.github.io/ArtifactManager/",
PackageInfoURL  := Concatenation( ~.PackageWWWHome, "PackageInfo.g" ),
README_URL      := Concatenation( ~.PackageWWWHome, "README.md" ),
ArchiveURL      := Concatenation( ~.SourceRepository.URL,
                                 "/releases/download/v", ~.Version,
                                 "/", ~.PackageName, "-", ~.Version ),

ArchiveFormats := ".tar.gz",

AbstractHTML   :=  "",

PackageDoc := rec(
  BookName  := "ArtifactManager",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0_mj.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Download and manage additional data files for your GAP package",
),

Dependencies := rec(
  GAP := ">= 4.13",
  NeededOtherPackages := [ ],
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

AvailabilityTest := ReturnTrue,

TestFile := "tst/testall.g",

#Keywords := [ "TODO" ],

));
