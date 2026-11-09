unit DependeciesGraf;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections, fphttpclient, opensslsockets, fpjson, jsonparser;

type
  TDependencyGraph = specialize TDictionary<string, TStringList>;

function BuildGraph(const RootPackage, RepoMode, TestFilePath, FilterSubstring: string): TDependencyGraph;
procedure FreeGraph(var Graph: TDependencyGraph);

implementation

const
  UrlNotFoundErrMsg = 'Package not found or network error';

function FetchNpmDependencies(const PackageName: string): TStringList;
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
      Client.AddHeader('Accept', 'application/vnd.npm.install-v1+json');
      RootData := GetJson(Client.Get('https://registry.npmjs.org/' + PackageName));
      
      if Client.ResponseStatusCode <> 200 then Exit;

      if not (RootData is TJSONObject) then Exit;
      RootObj := RootData as TJSONObject;

      if RootObj.Find('error') <> nil then Exit;

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
          Result.Add(DepsObj.Names[i]);
      end;
    except
    end;
  finally
    if RootData <> nil then RootData.Free;
    Client.Free;
  end;
end;

function FetchTestDependencies(const PackageName, TestFilePath: string): TStringList;
var
  Lines: TStringList;
  i: Integer;
  Line, DepsStr: string;
  Parts: TStringArray;
begin
  Result := TStringList.Create;
  Lines := TStringList.Create;
  try
    if not FileExists(TestFilePath) then Exit;
    Lines.LoadFromFile(TestFilePath);
    
    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);
      if Line = '' then Continue;
      
      Parts := Line.Split([':']);
      if (Length(Parts) = 2) and (Trim(Parts[0]) = PackageName) then
      begin
        DepsStr := Trim(Parts[1]);
        if DepsStr <> '' then
        begin
          Parts := DepsStr.Split([' ']);
          for Line in Parts do
            if Trim(Line) <> '' then Result.Add(Trim(Line));
        end;
        Break;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function GetDependencies(const PackageName, RepoMode, TestFilePath: string): TStringList;
begin
  if RepoMode = 'test' then
    Result := FetchTestDependencies(PackageName, TestFilePath)
  else
    Result := FetchNpmDependencies(PackageName);
end;

procedure ProcessLevel(const CurrentLevel: TStringList; const Visited: TStringList; 
  const Graph: TDependencyGraph; const RepoMode, TestFilePath, FilterSubstring: string);
var
  NextLevel: TStringList;
  i, j: Integer;
  PkgName, DepName: string;
  Deps: TStringList;
begin
  if CurrentLevel.Count = 0 then Exit; 

  NextLevel := TStringList.Create;
  try
    
    for i := 0 to CurrentLevel.Count - 1 do
    begin
      PkgName := CurrentLevel[i];
      
      
      Deps := GetDependencies(PkgName, RepoMode, TestFilePath);
      
      Graph.AddOrSetValue(PkgName, Deps);

      
      for j := 0 to Deps.Count - 1 do
      begin
        DepName := Deps[j];
        if (FilterSubstring <> '') and (Pos(FilterSubstring, DepName) > 0) then
          Continue;
        if Visited.IndexOf(DepName) = -1 then
        begin
          Visited.Add(DepName);
          NextLevel.Add(DepName);
        end;
      end;
    end;
    
    
    ProcessLevel(NextLevel, Visited, Graph, RepoMode, TestFilePath, FilterSubstring);
  finally
    NextLevel.Free;
  end;
end;

function BuildGraph(const RootPackage, RepoMode, TestFilePath, FilterSubstring: string): TDependencyGraph;
var
  Visited: TStringList;
  InitialLevel: TStringList;
begin
  Result := TDependencyGraph.Create;
  Visited := TStringList.Create;
  InitialLevel := TStringList.Create;
  try
    Visited.Add(RootPackage);
    InitialLevel.Add(RootPackage);
    ProcessLevel(InitialLevel, Visited, Result, RepoMode, TestFilePath, FilterSubstring);
  finally
    InitialLevel.Free;
    Visited.Free;
  end;
end;

procedure FreeGraph(var Graph: TDependencyGraph);
var
  List: TStringList;
begin
  if Graph <> nil then
  begin
    for List in Graph.Values do
      List.Free;
    Graph.Free;
    Graph := nil;
  end;
end;

end.
