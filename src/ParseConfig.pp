unit ParseConfig;
{$mode objfpc}{$H+}

interface
uses Classes, SysUtils, Process, StrUtils;


const
    ParamsCount = 6;
    parseYamlScript = 'parseYAML.sh';

type
    ConfigParamsElem = record
        key: string;
        value: string;
    end;
    ConfigParamsList = array of ConfigParamsElem;

procedure LoadParamsIntoList(yamlFileName: string; var listParams:ConfigParamsList);

implementation

var
    P: TProcess;
    Output: TStringList;
    ErrOutput: TStringList;

procedure StartYamlParseScript(filename: string);
begin
    P := TProcess.Create(nil);
    Output := TStringList.Create;
    P.Executable := '/bin/bash';
    P.Parameters.Add(ExtractFilePath(ParamStr(0)) + '../' +parseYamlScript);
    P.Parameters.Add(filename);
    P.Options := [poWaitOnExit, poUsePipes];
    P.Execute;
    if P.ExitStatus <> 0 then
    begin
        ErrOutput := TStringList.Create;
        try
            ErrOutput.LoadFromStream(P.Stderr);
            raise Exception.Create(Trim(ErrOutput.Text));
        finally
            ErrOutput.Free;
        end
    end
end;

procedure LoadParamsIntoList(yamlFileName: string; 
                          var listParams: ConfigParamsList);
var
    line, Key, Value: string;
    EqPos, i: integer;
begin
    StartYamlParseScript(yamlFileName);
    Output.LoadFromStream(P.Output);
    i := 0;
    try
        for line in Output do
        begin
            if Line = '' then continue;
            EqPos := Pos('=', Line);
            if EqPos = 0 then continue;
            Key := Copy(line, 1, EqPos - 1);
            Value := Copy(line, EqPos + 1, Length(Line) - EqPos);
            Key := Trim(Key);
            Value := Trim(Value);
            listParams[i].key := Key;
            listParams[i].value := Value;
            i := i + 1;
        end;
    finally
        Output.Free;
        P.Free
    end
end;

end.
