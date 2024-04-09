program passRef (input, output);
var x: integer;
    procedure g(y: integer; z: integer);
    var h: integer;
    begin
        h := h + 1;
    end;
begin
    x := 1;
    g(x);
end.
