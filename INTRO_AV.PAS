UNIT intro_av;

interface
procedure intro;
procedure intro2;
procedure play_start(select:byte);
procedure restore_color;
procedure espera(seg:byte);

implementation
uses grafix,motor2dv,keyboard;

const temps=65;
      color=205;

type t_bomba=record
          x,y:word;
     end;

var vscr,vscr_fons,virt_vga:ptr_pantalla;
    vaddr,vaddr_fons,vga2,cont:word;
    bomba,avio:t_bomba;
    fi:byte;
    i,line:word;
    red,green,blue:byte;

procedure init_mem;
begin
    setup_virtual(vscr,vaddr);
end;

procedure close_mem;
begin
    tancar_virtual(vscr);
end;
procedure espera(seg:byte);
begin
    for i:=1 to seg*temps do espera_vga;
end;

procedure play_start(select:byte);
begin
   if select=0 then get_color(color,red,green,blue);
   case select of
   0..63,128..191,255:set_color(color,red,green,blue);
   64..127,192..254:set_color(color,255,255,255);
   end;
end;

procedure restore_color;
begin
    set_color(color,red,green,blue);
end;

procedure intro;
var paleta:t_paleta;
begin
    init_mem;
    load_pcx('intro0.pcx',vaddr);
    volcar_pantalla(vaddr,$a000);
    espera(1);
    fadedown(0,0,0,1);
    load_pcx('intro1.pcx',vaddr);
    get_paleta(paleta);
    fadedown(0,0,0,1);
    volcar_pantalla(vaddr,$a000);
    fadeup(paleta,1);
    espera(1);
    fadedown(0,0,0,1);
    load_pcx('titol.pcx',vaddr);
    get_paleta(paleta);
    fadedown(0,0,0,1);
    volcar_pantalla(vaddr,$a000);
    fadeup(paleta,1);
    close_mem;
end;

procedure intro2a;
begin
    setup_virtual(vscr,vaddr);
    setup_virtual(virt_vga,vga2);
    setup_virtual(vscr_fons,vaddr_fons);
    cls(0,vaddr);
    cls(0,vga2);
    cls(0,vaddr_fons);
    load_pcx('models.pcx',vaddr);
    load_pcx('cel_s3.pcx',vaddr_fons);
    bomba.x:=140;bomba.y:=70;
    avio.x:=120;avio.y:=50;
end;

procedure moure_intro2a(var fi:byte);
begin
    cls(9,vga2);
    parallax_scroll(vaddr_fons,vga2,320*line);
    put_sprite(vaddr,vga2,69,9,18,bomba.x,bomba.y);{bomba}
    put_sprite(vaddr,vga2,84*320+41,41,82,avio.x,avio.y);{avio}
    espera_vga;
    volcar_pantalla(vga2,$a000);
    inc(bomba.x);inc(bomba.y);
    dec(avio.x);
    if (bomba.x>=310) or (bomba.y>=180) then fi:=1 else fi:=0;

    if fi=1 then fadedown(0,0,0,1);
end;

procedure intro2b;
begin
    load_pcx('jails.pcx',vaddr_fons);
    bomba.x:=120;
    bomba.y:=0;
end;

procedure moure_intro2b(var fi:byte);
begin
    volcar_pantalla(vaddr_fons,vga2);
    put_sprite(vaddr,vga2,69,9,18,bomba.x,bomba.y);{bomba}
    espera_vga;
    volcar_pantalla(vga2,$a000);
    inc(bomba.y);
    if (bomba.y>=100) then fi:=1 else fi:=0;
    if fi=1 then fadedown(0,0,0,1);
end;

procedure intro2c;
begin
    load_pcx('boom.pcx',vaddr_fons);
    cont:=0;
end;

procedure moure_intro2c(var fi:byte);
var i:byte;
begin
    cls(0,vga2);
    put_sprite(vaddr_fons,vga2,0,320,200,0,0);
    espera_vga;
    volcar_pantalla(vga2,$a000);
    for i:=1 to 4 do
    begin
     cls(0,vga2);
     put_sprite(vaddr_fons,vga2,0,320,200,i,random(4));
     espera_vga;
     volcar_pantalla(vga2,$a000);
    end;
    inc(cont);
    if cont=35 then
    begin
     fadedown(0,0,0,1);
     fi:=1;
    end;
end;


procedure acabar_intro2;
begin
    tancar_virtual(vscr);
    tancar_virtual(virt_vga);
    tancar_virtual(vscr_fons);
end;

procedure intro2;
begin
    line:=0;
    intro2a;
    fi:=0;
    repeat
    moure_intro2a(fi);
    inc(line);
    line:=line mod 200;
    until (qteclapuls) or (fi=1);
    intro2b;
    fi:=0;
    repeat
    moure_intro2b(fi);
    until (qteclapuls) or (fi=1);
    intro2c;
    fi:=0;
    repeat
    moure_intro2c(fi);
    until (qteclapuls) or (fi=1);
    acabar_intro2;
end;

end.