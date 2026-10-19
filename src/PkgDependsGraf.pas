program PkgDependsGraf;
{$mode objfpc}{$H+}

uses ParseConfig, SysUtils, fphttpclient, opensslsockets, fpjson, jsonparser, Classes;

const
    PackageNameYamlKey = 'package_name';
    RepoUrlYamlKey = 'repo_url';
    KeyNotFoundErrMsg = 'No such a key';
    NotNpmRepoPkgErrMsg = 'Only .npm packages';
    UrlNotFoundErrMsg = 'Package is not founded';

function FindValueByKey(var paramlist: ConfigParamsList; key: string): string;
var
    i: integer;
begin
    
    Result := KeyNotFoundErrMsg; 
    for i := 0 to Length(paramlist) - 1 do
    begin
        if key = paramlist[i].key then
        begin
            Result := paramlist[i].value;
            Exit; 
        end;
    end;
end;

function MakeURL(var paramlist: ConfigParamsList): string; 
var 
    packageName: string; 
    repoUrl: string;
begin
    packageName := FindValueByKey(paramlist, PackageNameYamlKey);
    repoUrl := FindValueByKey(paramlist, RepoUrlYamlKey); 
    
    
    if (packageName = KeyNotFoundErrMsg) or (repoUrl = KeyNotFoundErrMsg) then
    begin
        WriteLn(StdErr, KeyNotFoundErrMsg);
        Result := '';
        Exit;
    end;

    if Pos('registry.npmjs.org', repoUrl) = 0 then
    begin
        WriteLn(StdErr, NotNpmRepoPkgErrMsg);
        Result := '';
        Exit;
    end;

    if repoUrl[Length(repoUrl)] = '/' then
        Delete(repoUrl, Length(repoUrl), 1);

    Result := repoUrl + '/' + packageName;
end;

function GetPkgDependicies(url: string): TStringList;
var
    Client: TFPHTTPClient;
    RootData, VersionData: TJSONData;
    RootObj, DistTagsObj, VersionsObj, SpecificVersionObj, DepsObj: TJSONObject;
    LatestVersion: string;
    i: integer;
begin
    Result := TStringList.Create;
    Client := TFPHTTPClient.Create(nil);
    RootData := nil;
    try
        try
            RootData := GetJson(Client.get(url));
        except 
            on E: Exception do
            begin
                WriteLn(StdErr, UrlNotFoundErrMsg);
                halt
            end
        end;
        try
            if not (RootData is TJSONObject) then Exit;
            RootObj := RootData as TJSONObject;

            if RootObj.Find('error') <> nil then
            begin
                WriteLn(StdErr, UrlNotFoundErrMsg);
                halt
            end;

            if not (RootObj.Find('dist-tags') is TJSONObject) then Exit;
            DistTagsObj := RootObj.Find('dist-tags') as TJSONObject;
            
            if not (DistTagsObj.Find('latest') is TJSONString) then Exit;
            LatestVersion := DistTagsObj.Find('latest').AsString;

            if not (RootObj.Find('versions') is TJSONObject) then Exit;
            VersionsObj := RootObj.Find('versions') as TJSONObject;

            VersionData := VersionsObj.Find(LatestVersion);
            if not (VersionData is TJSONObject) then Exit;
            SpecificVersionObj := VersionData as TJSONObject;

            if SpecificVersionObj.Find('dependencies') is TJSONObject then
            begin
                DepsObj := SpecificVersionObj.Find('dependencies') as TJSONObject;
                for i := 0 to DepsObj.Count - 1 do
                    Result.Add(DepsObj.Names[i] + ' ' + 
                        '(' + DepsObj.Items[i].AsString + ')');
            end;
            
        finally
            RootData.Free;
        end;
    finally
        Client.Free;
    end;
end;

var 
    listOfParams: ConfigParamsList;
    ConfFileName: string;
    url: string;
    listOfDependicies: TStringList;
    i: Integer;
begin
    
    if ParamCount < 1 then
    begin
        WriteLn(StdErr, 'Usage: ', ParamStr(0), ' <config.yaml>');
        Halt(1);
    end;

    ConfFileName := ParamStr(1);
    SetLength(listOfParams, ParamsCount);
    
    try
        LoadParamsIntoList(ConfFileName, listOfParams);
    except
        on E: Exception do
        begin
            WriteLn(StdErr, E.Message);
            Halt(1);
        end;
    end;

    url := MakeURL(listOfParams);
    
    if url <> '' then
    begin
        listOfDependicies := GetPkgDependicies(url);
        try
            WriteLn('Dependencies for ', FindValueByKey(listOfParams, PackageNameYamlKey), ':');
            for i := 0 to listOfDependicies.Count - 1 do
                WriteLn(' - ', listOfDependicies[i]);
            if listOfDependicies.Count = 0 then
                WriteLn('No dependencies');
        finally
            listOfDependicies.Free; 
        end;
    end;
end.
