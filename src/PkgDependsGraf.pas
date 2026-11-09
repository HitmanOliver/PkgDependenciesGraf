program PkgDependsGraf;
{$mode objfpc}{$H+}

uses
  ParseConfig, DependeciesGraf, SysUtils, Classes;

function FindValueByKey(const paramlist: ConfigParamsList; const key: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to Length(paramlist) - 1 do
    if key = paramlist[i].key then
    begin
      Result := paramlist[i].value;
      Exit;
    end;
end;

procedure PrintGraphTree(const Graph: TDependencyGraph; const PackageName: string; 
                         Level: Integer; Path: TStringList);
var
  Deps: TStringList;
  Dep: string;
begin
  Write(StringOfChar(' ', Level * 2));
  WriteLn('- ', PackageName);

  if Path.IndexOf(PackageName) >= 0 then
  begin
    Write(StringOfChar(' ', (Level + 1) * 2));
    WriteLn('(cyclic dependency)');
    Exit;
  end;

  if not Graph.TryGetValue(PackageName, Deps) then
    Exit;

  Path.Add(PackageName);
  try
    for Dep in Deps do
    begin
      PrintGraphTree(Graph, Dep, Level + 1, Path);
    end;
  finally
    Path.Delete(Path.Count - 1);
  end;
end;

var 
  listOfParams: ConfigParamsList;
  ConfFileName, PackageName, RepoUrl, RepoMode, FilterSub: string;
  Graph: TDependencyGraph;
  GraphKeys: TStringList;
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

  {Извлекаем параметры}
  PackageName := FindValueByKey(listOfParams, 'package_name');
  RepoUrl     := FindValueByKey(listOfParams, 'repo_url');
  RepoMode    := FindValueByKey(listOfParams, 'repo_mode');
  FilterSub   := FindValueByKey(listOfParams, 'filter_substring');

  if (PackageName = '') or (RepoUrl = '') then
  begin
    WriteLn(StdErr, 'Missing required config parameters');
    Halt(1);
  end;

  WriteLn('Building graph for package: ', PackageName, ' [Mode: ', RepoMode, ']');
  
  Graph := BuildGraph(PackageName, RepoMode, RepoUrl, FilterSub);
  try
    WriteLn('--- Graf built ---');
    
    GraphKeys := TStringList.Create;
    try
      PrintGraphTree(Graph, PackageName, 0, GraphKeys);
    finally
      GraphKeys.Free;
    end;

  finally
    FreeGraph(Graph);
  end;
end.
