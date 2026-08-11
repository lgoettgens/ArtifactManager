#
# ArtifactManager: Download and manage additional data files for your GAP package
#
# Implementations
#

InstallGlobalFunction( ArtifactManager_Error,
function( filename, message )
    Error( Concatenation( "ArtifactManager: ", filename, ": ", message ) );
end );

InstallGlobalFunction( ArtifactManager_ReadManifest,
function( filename )
    if not IsString( filename ) then
        Error( "ArtifactManager: manifest filename must be a string" );
    fi;
    if IsExistingFile( filename ) <> true then
        ArtifactManager_Error( filename, "manifest file does not exist" );
    fi;
    return ReadAsFunction( filename )();
end );

InstallGlobalFunction( ArtifactManager_ValidateManifest,
function( filename, entries )
    local allowedArtifactFields, allowedDownloadFields, entry, download, field,
          index, downloadIndex, seenNames, seenURLs;

    allowedArtifactFields := [ "downloads", "lazy", "name", "tree_sha256" ];
    allowedDownloadFields := [ "sha256", "url" ];
    if not IsList( entries ) then
        ArtifactManager_Error( filename, "manifest must return a list" );
    fi;

    seenNames := [ ];
    for index in [ 1 .. Length( entries ) ] do
        entry := entries[ index ];
        if not IsRecord( entry ) then
            ArtifactManager_Error( filename,
                Concatenation( "artifact #", String( index ), " must be a record" ) );
        fi;

        for field in RecNames( entry ) do
            if not field in allowedArtifactFields then
                ArtifactManager_Error( filename,
                    Concatenation( "artifact #", String( index ),
                    " has unknown field '", field, "'" ) );
            fi;
        od;

        if not IsBound( entry.name ) or not IsString( entry.name )
           or Length( entry.name ) = 0 then
            ArtifactManager_Error( filename,
                Concatenation( "artifact #", String( index ),
                " must have a nonempty string 'name'" ) );
        fi;
        if entry.name in seenNames then
            ArtifactManager_Error( filename,
                Concatenation( "artifact name '", entry.name,
                "' is declared more than once" ) );
        fi;
        Add( seenNames, entry.name );

        if not IsBound( entry.tree_sha256 ) then
            ArtifactManager_Error( filename,
                Concatenation( "artifact '", entry.name,
                "' is missing 'tree_sha256'" ) );
        fi;
        if not IsString( entry.tree_sha256 )
           or Length( entry.tree_sha256 ) <> 64
           or not ForAll( entry.tree_sha256,
                char -> char in "0123456789abcdef" ) then
            ArtifactManager_Error( filename,
                Concatenation( "artifact '", entry.name,
                "' has an invalid 'tree_sha256'" ) );
        fi;

        if not IsBound( entry.lazy ) then
            ArtifactManager_Error( filename,
                Concatenation( "artifact '", entry.name,
                "' is missing 'lazy'" ) );
        fi;
        if entry.lazy <> true then
            ArtifactManager_Error( filename,
                Concatenation( "artifact '", entry.name,
                "' has invalid 'lazy' (currently only 'true' is supported)" ) );
        fi;

        if not IsBound( entry.downloads ) then
            ArtifactManager_Error( filename,
                Concatenation( "artifact '", entry.name,
                "' is missing 'downloads'" ) );
        fi;
        if not IsList( entry.downloads ) or Length( entry.downloads ) = 0 then
            ArtifactManager_Error( filename,
                Concatenation( "artifact '", entry.name,
                "' must have a nonempty 'downloads' list" ) );
        fi;

        seenURLs := [ ];
        for downloadIndex in [ 1 .. Length( entry.downloads ) ] do
            download := entry.downloads[ downloadIndex ];
            if not IsRecord( download ) then
                ArtifactManager_Error( filename,
                    Concatenation( "artifact '", entry.name,
                    "', download #", String( downloadIndex ),
                    " must be a record" ) );
            fi;
            for field in RecNames( download ) do
                if not field in allowedDownloadFields then
                    ArtifactManager_Error( filename,
                        Concatenation( "artifact '", entry.name,
                        "', download #", String( downloadIndex ),
                        " has unknown field '",
                        field, "'" ) );
                fi;
            od;

            if not IsBound( download.url ) then
                ArtifactManager_Error( filename,
                    Concatenation( "artifact '", entry.name,
                    "', download #", String( downloadIndex ),
                    " is missing 'url'" ) );
            fi;
            if not IsString( download.url )
               or not StartsWith( download.url, "https://" )
               or Length( download.url ) = 8 or download.url[ 9 ] = '/'
               or ForAny( download.url, char -> char in " \t\r\n" ) then
                ArtifactManager_Error( filename,
                    Concatenation( "artifact '", entry.name,
                    "', download #", String( downloadIndex ),
                    " has invalid 'url'" ) );
            fi;
            if download.url in seenURLs then
                ArtifactManager_Error( filename,
                    Concatenation( "artifact '", entry.name,
                    "' declares URL '", download.url, "' more than once" ) );
            fi;
            Add( seenURLs, download.url );
            if not IsBound( download.sha256 ) then
                ArtifactManager_Error( filename,
                    Concatenation( "artifact '", entry.name,
                    "', download #", String( downloadIndex ),
                    " is missing 'sha256'" ) );
            fi;

            if not IsString( download.sha256 )
               or Length( download.sha256 ) <> 64
               or not ForAll( download.sha256,
                    char -> char in "0123456789abcdef" ) then
                ArtifactManager_Error( filename,
                    Concatenation( "artifact '", entry.name,
                    "', download #", String( downloadIndex ),
                    " has invalid 'sha256'" ) );
            fi;
        od;
    od;
    return entries;
end );

InstallGlobalFunction( ArtifactManager_ResolveArtifact,
function( name, artifacts, filename )
    local artifact;

    if not IsString( name ) or Length( name ) = 0 then
        ArtifactManager_Error( filename, "artifact name must be a nonempty string" );
    fi;
    artifact := First( artifacts, entry -> entry.name = name );
    if artifact = fail then
        ArtifactManager_Error( filename,
            Concatenation( "artifact '", name, "' is not declared" ) );
    fi;
    return artifact;
end );

InstallGlobalFunction( ListArtifacts,
function( manifest )
    return ArtifactManager_ValidateManifest(
        manifest, ArtifactManager_ReadManifest( manifest ) );
end );

InstallGlobalFunction( ArtifactMetadata,
function( name, manifest )
    return ArtifactManager_ResolveArtifact(
        name, ListArtifacts( manifest ), manifest );
end );

InstallGlobalFunction( ArtifactHash,
function( name, manifest )
    return ArtifactMetadata( name, manifest ).tree_sha256;
end );
