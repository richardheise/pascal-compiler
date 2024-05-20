program passRef (input, output);
var x: integer;
    procedure p(var y: integer; z: integer);
    var h: integer;
    begin
        h := h + 1;
    end;

    function f() : integer;
    begin
        f:= 89;
    end;
begin
    write(f());
end.
