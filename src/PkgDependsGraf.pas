program PkgDependsGraf;
{$mode objfpc}
{$H+}

uses ParseConfig, SysUtils;


var 
    listOfParams: ConfigParamsList;
    ConfFileName: string;
    i: integer;
begin
    ConfFileName := argv[1];
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
    for i := 0 to (ParamsCount - 1) do
    begin
        if listOfParams[i].key = '' then continue;
        write(i + 1, ') ');
        writeln(listOfParams[i].key + '=' + listOfParams[i].value);
    end
    
end.
