program aero_j;

uses crt,dos,grafix,keyboard,motor2dv,mtravio,av_malos,intro_av,optimiza;

{------------------------------------------------------------------------}
var vscr,vscr2,vga2,vscr3,vscr4,vscr_mort,vscr_missatges,vscr_misio:ptr_pantalla;
    vaddr,vaddr2,vaddr3,virt_vga,vaddr4,i,vaddr_mort,vaddr_missatges,vaddr_misio:word;
    avio,avio_malo,avio_malo2:avio_obj;
    explosio:t_explosions;
    ammo,ammo_mala:t_municio;
    tecla,defeated:byte;
    kills,vides,life_boss:word;
    fase_kills:word;
    off_avio,off_boss,v_scroll1,v_scroll2:word;
    num_fase,ultima_tecla,timer,color,mode_auto,no_pintar,inv:byte;
    temps,first_temps,linies:word;
    cont_temps,cont_frames:longint;


{====================== Informacio ========================}
procedure pinta_escut;
const off_escut=84*320;
      ample_escut=41;
      alt_escut=42;
begin
     put_sprite(vaddr2,virt_vga,off_escut,ample_escut,alt_escut,avio.x,avio.y);
end;

procedure pinta_bombes;
var cont:byte;
begin
    if avio.bombes>0 then
    for cont:=1 to avio.bombes do
     put_sprite(vaddr2,virt_vga,43,13,13,0+(cont*4),186);
end;

procedure pinta_vides;
var cont:byte;
begin
    if vides>0 then
     for cont:=0 to vides-1 do
     put_sprite(vaddr2,virt_vga,56,13,13,0+(cont*10),10);
end;

procedure auto_mode(var avio:avio_obj;var auto:byte);
begin
    avio.y:=avio.y-2;
    if avio.y<=100 then auto:=0 else auto:=1;
end;
{============================bales=========================}
procedure gestiona_bales(var muni:t_municio;sentit:integer);
{pinta i mou les bales que hi ha en pantalla}
var cont:byte;
begin
   for cont:=1 to max_bales do
   case sentit of
   -1:
    begin
    if (muni.bales[cont].y>0) and (muni.bales[cont].activa=1) then begin
                        moure_bala(muni.bales[cont],sentit);
                        put_sprite(vaddr2,virt_vga,off_bala,bala_ample,bala_alt,muni.bales[cont].x,muni.bales[cont].y);
                        end
    end;
   1:begin
     if (muni.bales[cont].y<199) and (muni.bales[cont].activa=1) then begin
         moure_bala(muni.bales[cont],sentit);
         put_sprite(vaddr2,virt_vga,off_bala_malo,bala_ample_malo,bala_alt_malo,muni.bales[cont].x,muni.bales[cont].y);
         end;
    end;
   end;
end;

{========================explosions======================}
procedure gestiona_explosions;
{pinta i actualitza en pantalla les explosions i les elimina si ha pasat el temps de durada}
var cont:byte;
begin
   for cont:=1 to max_explosions do
    if explosio.cadena_expl[cont].activa=1 then
      begin
      put_sprite(vaddr2,virt_vga,82,41,42,explosio.cadena_expl[cont].x,explosio.cadena_expl[cont].y);
      dec(explosio.cadena_expl[cont].time);
      if explosio.cadena_expl[cont].time=0 then explosio.cadena_expl[cont].activa:=0;
    end;
end;


{----------- Avions ----- malos------------------------------------}
procedure gestiona_mort_malos(var avio_m:avio_obj);
{gestio mort malos i "eliminacio" de bales}
var cont:byte;mort:byte;
begin
    gestiona_mort_avio(avio_malo,ammo,explosio,mort);
    kills:=kills+mort;
end;

{----------- Boss -----------------------------------------}

procedure dispara_boss(var ammo_mala:t_municio;plane:avio_obj;tipus:byte);
begin
    case tipus of
    1:begin
      if (ammo_mala.bales[ammo_mala.n_bala].activa=0) and
       (ammo_mala.bales[ammo_mala.n_bala+1].activa=0) then
       begin
        crea_bala(ammo_mala.bales[ammo_mala.n_bala],plane.x+8,plane.y+plane.maxy+1);
        crea_bala(ammo_mala.bales[ammo_mala.n_bala+1],plane.x+avio_alt-8,plane.y+plane.maxy+1);
        ammo_mala.n_bala:=(ammo_mala.n_bala+2) mod max_bales_malos;
       end;
      end;
    2:begin
      if (ammo_mala.bales[ammo_mala.n_bala].activa=0) and
       (ammo_mala.bales[ammo_mala.n_bala+1].activa=0) then
       begin
        crea_bala(ammo_mala.bales[ammo_mala.n_bala],plane.x+21,plane.y+plane.maxy+1);
        crea_bala(ammo_mala.bales[ammo_mala.n_bala+1],plane.x+40,plane.y+plane.maxy+1);
        crea_bala(ammo_mala.bales[ammo_mala.n_bala+2],plane.x,plane.y+plane.maxy+1);
        crea_bala(ammo_mala.bales[ammo_mala.n_bala+3],plane.x+plane.maxx,plane.y+plane.maxy+1);
        ammo_mala.n_bala:=(ammo_mala.n_bala+4) mod max_bales_malos;
       end;
      end;
    end;
end;

procedure moure_boss(var plane:avio_obj;bo:avio_obj;var bales_malo:t_municio;inteligencia:byte;dispar:byte);
var sentit:integer;
begin
   case inteligencia of
   1:begin
      if (plane.x<309-plane.maxx) and (plane.sentit_x=2) then plane.sentit_x:=2
      else plane.sentit_x:=-2;
      if (plane.x<=0) and (plane.sentit_x=-2) then plane.sentit_x:=2;
      if (plane.x>bo.x) and (plane.sentit_x>0) then plane.sentit_x:=-2;

      if (plane.y<plane.maxy) and (plane.sentit_y=1) then plane.sentit_y:=1
        else plane.sentit_y:=-1;
      if (plane.y<=0) and (plane.sentit_y=-1) then plane.sentit_y:=1;
      dispara_boss(bales_malo,plane,dispar);
     end;
   2:begin
      if (plane.x<309-plane.maxx) and (plane.sentit_x=2) then plane.sentit_x:=2
      else plane.sentit_x:=-2;
      if (plane.x<=10) and (plane.sentit_x=-2) then plane.sentit_x:=2;
      dispara_boss(bales_malo,plane,dispar);
      plane.sentit_y:=0;
     end;
   3:begin
      if (plane.x<309-plane.maxx) and (plane.sentit_x=2) then plane.sentit_x:=2
      else plane.sentit_x:=-2;
      if (plane.x<=0) and (plane.sentit_x=-2) then plane.sentit_x:=2;
      if (plane.x>bo.x) and (plane.sentit_x>0) then plane.sentit_x:=-2;
      plane.sentit_y:=0;
      dispara_boss(bales_malo,plane,dispar);
     end;
   end;
    plane.x:=plane.x+(plane.sentit_x);
    plane.y:=plane.y+(plane.sentit_y);
end;


procedure pintar_boss(var avio_m:avio_obj;offset:word);
{pinta boss}
begin
    if avio_m.y<200-30 then
    put_sprite(vaddr2,virt_vga,offset,avio_m.maxx,avio_m.maxy,avio_m.x,avio_m.y);
    if avio_m.y>200 then elimina_malo(avio_m);
end;


procedure gestiona_mort_boss(var avio_m:avio_obj;var vida:word);
{gestio mort boss i bales}
var cont:byte;
begin
    for cont:=1 to max_bales do
    if ammo.bales[cont].activa=1 then
    if
     test_colisio(ammo.bales[cont].x,ammo.bales[cont].y,2,2,avio_m.x,avio_m.y,avio_m.maxx,avio_m.maxy) then
     begin
      explosio.n_explosio:=(explosio.n_explosio mod max_explosions)+1;
      explosio.cadena_expl[explosio.n_explosio].x:=ammo.bales[cont].x-9;
      if ammo.bales[cont].y-9>=0 then
       explosio.cadena_expl[explosio.n_explosio].y:=ammo.bales[cont].y-9
      else explosio.cadena_expl[explosio.n_explosio].y:=ammo.bales[cont].y;
      explosio.cadena_expl[explosio.n_explosio].time:=temps_explosio;
      explosio.cadena_expl[explosio.n_explosio].activa:=1;
      dec(vida);
     if vida<=0 then
     begin
      elimina_malo(avio_m);
      defeated:=1;
     end;
      elimina_bala(ammo.bales[cont]);
     end;
end;
{----------------- Avio -- bo ---------------------------------}
procedure gestiona_mort(var mode:byte);
{gestio mort del bo}
var cont,mort:byte;
begin
    if avio.invencible=0 then
    if
     test_colisio(avio.x,avio.y,avio.maxx,avio.maxy,avio_malo.x,
     avio_malo.y,avio_malo.maxx,avio_malo.maxy) then
     begin
      explosio.n_explosio:=(explosio.n_explosio mod max_explosions)+1;
      explosio.cadena_expl[explosio.n_explosio].x:=avio.x;
      explosio.cadena_expl[explosio.n_explosio].y:=avio.y;
      explosio.cadena_expl[explosio.n_explosio].time:=temps_explosio*3;
      explosio.cadena_expl[explosio.n_explosio].activa:=1;
      dec(vides);
      avio.x:=100;
      avio.y:=160;
      avio.bombes:=max_bombes;
      posar_invencible(avio);
      auto_mode(avio,mode);
     end;
    if avio.invencible=0 then gestiona_mort_avio(avio,ammo_mala,explosio,mort);
    if mort=1 then
    begin
     dec(vides);
     avio.x:=100;
     avio.y:=160;
     avio.bombes:=max_bombes;
     posar_invencible(avio);
     auto_mode(avio,mode);
    end;
     if mode=1 then
     begin
      if (explosio.cadena_expl[explosio.n_explosio].activa=0)
      and (explosio.cadena_expl[explosio.n_explosio].time=0) then
      begin
      auto_mode(avio,mode);
      posar_invencible(avio);
      no_pintar:=0;
      end
      else no_pintar:=1;
     end;
     if avio.temps_invencible>0 then dec(avio.temps_invencible);
     if avio.temps_invencible=0 then avio.invencible:=0;
end;

{===============Procediments sobre l'scroll i iniciar joc i fases=========}
procedure gestio_pantalla;
var vf,v1,v2,ratio1,ratio2:word;
begin
    ratio1:=200 div (v_scroll1 div velocitat_fons);
    ratio2:=200 div (v_scroll2 div velocitat_fons);
    vf:=((velocitat_fons*linies) mod 64000);
    v1:=((v_scroll1*(linies mod ratio1)) mod 64000);
    v2:=((v_scroll2*(linies mod ratio2)) mod 64000);
    scroll(vaddr4,virt_vga,vf);
    parallax_scroll(vaddr3,virt_vga,v2);
    parallax_scroll(vaddr,virt_vga,v1);
    if no_pintar=0 then put_sprite(vaddr2,virt_vga,off_avio_bo,avio_alt,avio_ample,avio.x,avio.y);
end;

procedure gestio_pantalla_boss;
var vf,v1,v2,ratio1,ratio2:word;
begin
    ratio1:=200 div (v_scroll1 div velocitat_fons);
    ratio2:=200 div (v_scroll2 div velocitat_fons);
    vf:=((velocitat_fons*2*linies) mod 64000);
    v1:=((v_scroll1*(linies mod ratio1)) mod 64000);
    v2:=((v_scroll2*(linies mod ratio2)) mod 64000);
    scroll(vaddr4,virt_vga,vf);
    parallax_scroll(vaddr3,virt_vga,v2);
    parallax_scroll(vaddr,virt_vga,v1);
    if no_pintar=0 then put_sprite(vaddr2,virt_vga,off_avio_bo,avio_alt,avio_ample,avio.x,avio.y);
end;

procedure setup_fase1;
begin
    cls(0,vaddr);
    load_pcx('cel_s1.pcx',vaddr);
    cls(0,vaddr3);
    load_pcx('avions_f.pcx',vaddr3);
    cls(0,vaddr4);
    load_pcx('stage1.pcx',vaddr4);
    cls(0,vaddr2);
    load_pcx('models.pcx',vaddr2);
    cls(0,virt_vga);

    fase_kills:=fase1_kills;
    off_avio:=off_avio_m1;
    off_boss:=off_boss1;
    life_boss:=200;
    v_scroll1:=640;
    v_scroll2:=1280;
end;

procedure setup_fase2;
begin
    cls(0,vaddr);
    load_pcx('cel_s2.pcx',vaddr);
    cls(0,vaddr3);
    load_pcx('tanks1.pcx',vaddr3);
    cls(0,vaddr4);
    load_pcx('stage2.pcx',vaddr4);
    cls(0,vaddr2);
    load_pcx('models.pcx',vaddr2);
    cls(0,virt_vga);

    fase_kills:=fase2_kills;
    life_boss:=400;
    off_boss:=off_boss2;
    off_avio:=off_avio_m2;
    v_scroll1:=960;
    v_scroll2:=640;
end;

procedure setup_fase3;
begin
    cls(0,vaddr);
    load_pcx('cel_s3.pcx',vaddr);
    cls(0,vaddr3);
    load_pcx('barcos.pcx',vaddr3);
    cls(0,vaddr4);
    load_pcx('stage3.pcx',vaddr4);
    cls(0,vaddr2);
    load_pcx('models.pcx',vaddr2);
    cls(0,virt_vga);

    fase_kills:=fase3_kills;
    off_avio:=off_avio_m3;
    life_boss:=800;
    off_boss:=off_boss3;
    v_scroll1:=640;
    v_scroll2:=320;
end;

procedure setup_fase4;
begin
    cls(0,vaddr);
    load_pcx('cel_s4.pcx',vaddr);
    cls(0,vaddr3);
    load_pcx('cotxes.pcx',vaddr3);
    cls(0,vaddr4);
    load_pcx('stage4.pcx',vaddr4);
    cls(0,vaddr2);
    load_pcx('models.pcx',vaddr2);
    cls(0,virt_vga);

    fase_kills:=fase4_kills;
    off_avio:=off_avio_m4;
    life_boss:=1600;
    off_boss:=off_boss4;
    v_scroll1:=960;
    v_scroll2:=640;
end;

procedure setup_fase5;
begin
    cls(0,vaddr);
    load_pcx('cel_s5.pcx',vaddr);
    cls(0,vaddr3);
    load_pcx('nuvols.pcx',vaddr3);
    cls(0,vaddr4);
    load_pcx('stage5.pcx',vaddr4);
    cls(0,vaddr2);
    load_pcx('models.pcx',vaddr2);
    cls(0,virt_vga);

    fase_kills:=fase5_kills;
    off_avio:=off_avio_m5;
    life_boss:=3200;
    off_boss:=off_boss5;
    v_scroll1:=960;
    v_scroll2:=640;
end;



procedure setup_fase(n_fase:byte);
var bombes:byte;
begin
     case n_fase of
      1:setup_fase1;
      2:setup_fase2;
      3:setup_fase3;
      4:setup_fase4;
      5:setup_fase5;
      6:;
     end;
     inicia_municio(ammo);
     inicia_municio(ammo_mala);
     inicia_explosions(explosio);
     bombes:=avio.bombes;
     crea_avio(avio,100,160,avio_alt,avio_ample);
     crea_avio(avio_malo,0,0,41,42);
     mode_auto:=0;
     defeated:=0;
     kills:=0;
     inc(vides);
     posar_invencible(avio);
     timer:=100;
     avio.bombes:=bombes;
     posar_bombes(avio)
end;

procedure setup_game;
begin
   setup_virtual(vscr,vaddr);
   setup_virtual(vscr2,vaddr2);
   setup_virtual(vscr3,vaddr3);
   setup_virtual(vscr4,vaddr4);
   setup_virtual(vga2,virt_vga);
   vides:=4;
   setup_fase(num_fase);
   ultima_tecla:=$00;
   no_pintar:=0;
   linies:=0;
end;

procedure fi_joc;
begin
    tancar_virtual(vscr);
    tancar_virtual(vscr2);
    tancar_virtual(vscr3);
    tancar_virtual(vga2);
    tancar_virtual(vscr4)
end;

procedure select_boss;
begin
   case num_fase of
      1:begin
          crea_avio(avio_malo,0,0,122,41);
          avio_malo.sentit_x:=2;
          avio_malo.sentit_y:=1;
        end;
      2:begin
          crea_avio(avio_malo,0,0,85,84);
          avio_malo.sentit_x:=2;
          avio_malo.sentit_y:=1;
      end;
      3:begin
          crea_avio(avio_malo,0,0,41,41);
          avio_malo.sentit_x:=2;
          avio_malo.sentit_y:=1;

          crea_avio(avio_malo2,0,0,41,41);
          avio_malo2.sentit_x:=2;
          avio_malo2.sentit_y:=0;
      end;
      4:begin
          crea_avio(avio_malo,0,0,75,41);
          avio_malo.sentit_x:=2;
          avio_malo.sentit_y:=1;
        end;
      5:begin
            crea_avio(avio_malo,0,0,85,100);
            avio_malo.sentit_x:=2;
            avio_malo.sentit_y:=1;
        end;
     end;
end;

procedure gestiona_mort_boss_fase;
begin
    case num_fase of
      1:begin
         gestiona_mort_boss(avio_malo,life_boss);
        end;
      2:begin
         gestiona_mort_boss(avio_malo,life_boss);
        end;
      3:begin
         gestiona_mort_boss(avio_malo,life_boss);
         gestiona_mort_boss(avio_malo2,life_boss);
        end;
      4:begin
         gestiona_mort_boss(avio_malo,life_boss);
        end;
      5:begin
         gestiona_mort_boss(avio_malo,life_boss);
        end;
      end;
end;

procedure moure_boss_fase;
begin
     case num_fase of
       1:begin
          moure_boss(avio_malo,avio,ammo_mala,1,1);
          pintar_boss(avio_malo,off_boss);
         end;
       2:begin
          moure_boss(avio_malo,avio,ammo_mala,1,1);
          pintar_boss(avio_malo,off_boss);
         end;
       3:begin
          moure_boss(avio_malo,avio,ammo_mala,1,1);
          pintar_boss(avio_malo,off_boss);
          moure_boss(avio_malo2,avio,ammo_mala,2,1);
          pintar_boss(avio_malo2,off_boss);
         end;
       4:begin
          moure_boss(avio_malo,avio,ammo_mala,1,2);
          pintar_boss(avio_malo,off_boss);
         end;
       5:begin
          moure_boss(avio_malo,avio,ammo_mala,3,2);
          pintar_boss(avio_malo,off_boss);
          end;
      end;
end;

procedure pinta_mission;
begin
    put_sprite(vaddr2,virt_vga,320*187,172,15,70,80);
end;

procedure pinta_num_mission(num:byte);
begin
    put_sprite(vaddr2,virt_vga,320*166+(17*(num-1)),17,20,145,100);
end;

procedure load_jailer(nom:integer);
begin
     case nom of
      1{jailgamer}:begin
                    load_pcx('jailers1.pcx',vaddr_missatges);
                    put_sprite(vaddr_missatges,vaddr_misio,0,84,128,16,6);
                   end;
      2{masterjail}:begin
                     load_pcx('jailers1.pcx',vaddr_missatges);
                     put_sprite(vaddr_missatges,vaddr_misio,85,84,128,16,6);
                    end;
      3{jaildoctor}:begin
                     load_pcx('jailers1.pcx',vaddr_missatges);
                     put_sprite(vaddr_missatges,vaddr_misio,170,84,128,16,6);
                    end;
      4{jailwebmaster}:begin
                        load_pcx('jailers2.pcx',vaddr_missatges);
                        put_sprite(vaddr_missatges,vaddr_misio,0,84,128,16,6);
                    end;
      5{jailsleeper}:begin
                      load_pcx('jailers2.pcx',vaddr_missatges);
                      put_sprite(vaddr_missatges,vaddr_misio,85,84,128,16,6);
                     end;
      6{jailprogramer}:begin
                        load_pcx('jailers2.pcx',vaddr_missatges);
                        put_sprite(vaddr_missatges,vaddr_misio,170,84,128,16,6);
                       end;
      7{jaildesigner}:begin
                       load_pcx('jailers3.pcx',vaddr_missatges);
                       put_sprite(vaddr_missatges,vaddr_misio,0,84,128,16,6);
                      end;
      8{jailmerchandiser}:begin
                           load_pcx('jailers3.pcx',vaddr_missatges);
                           put_sprite(vaddr_missatges,vaddr_misio,85,84,128,16,6);
                          end;
      9{jailarounder}:begin
                       load_pcx('jailers3.pcx',vaddr_missatges);
                       put_sprite(vaddr_missatges,vaddr_misio,170,84,128,16,6);
                      end;
      10{jailhardwarer}:begin
                         load_pcx('jailers4.pcx',vaddr_missatges);
                         put_sprite(vaddr_missatges,vaddr_misio,0,84,128,16,6);
                        end;
      11{jailhacker}:begin
                      load_pcx('jailers4.pcx',vaddr_missatges);
                      put_sprite(vaddr_missatges,vaddr_misio,85,84,128,16,6);
                     end;
      12{jailfriend}:begin
                      load_pcx('jailers4.pcx',vaddr_missatges);
                      put_sprite(vaddr_missatges,vaddr_misio,170,84,128,16,6);
                     end;
     end;
end;

procedure info_mission(fase:byte);
begin
   setup_virtual(vscr_misio,vaddr_misio);
   cls(0,vaddr_misio);
   load_pcx('missions.pcx',vaddr_misio);
   setup_virtual(vscr_missatges,vaddr_missatges);
   cls(0,vaddr_missatges);
   load_jailer(random(12)+1);
   cls(0,vaddr_missatges);
   load_pcx('missatge.pcx',vaddr_missatges);
   case fase of
    1:begin
       put_sprite(vaddr_missatges,vaddr_misio,off_misatge1,ample_misatge1,alt_misatge1,10,159);
       volcar_pantalla(vaddr_misio,$a000);
      end;
    2:begin
       put_sprite(vaddr_missatges,vaddr_misio,off_misatge2,ample_misatge2,alt_misatge2,10,159);
       volcar_pantalla(vaddr_misio,$a000);
      end;
    3:begin
       put_sprite(vaddr_missatges,vaddr_misio,off_misatge3,ample_misatge3,alt_misatge3,10,159);
       volcar_pantalla(vaddr_misio,$a000);
      end;
    4:begin
       put_sprite(vaddr_missatges,vaddr_misio,off_misatge4,ample_misatge4,alt_misatge4,10,159);
       volcar_pantalla(vaddr_misio,$a000);
      end;
    5:begin
       put_sprite(vaddr_missatges,vaddr_misio,off_misatge5,ample_misatge5,alt_misatge5,10,159);
       volcar_pantalla(vaddr_misio,$a000);
      end;
    6:begin
       put_sprite(vaddr_missatges,vaddr_misio,off_misatge6,ample_misatge6,alt_misatge6,10,159);
       volcar_pantalla(vaddr_misio,$a000);
      end;
   end;
   repeat until qteclapuls;
   tancar_virtual(vscr_misio);
   tancar_virtual(vscr_missatges);
end;

{========================================================}
{                  Programa principal                    }
{========================================================}
begin
  repeat
    setmode($13);
    randomize;
    instalarkb;
    intro;
    color:=0;
    first_temps:=0;
    repeat
     play_start(color);
     inc(color);
     color:=color mod 256;
     espera_vga;
     temps:=gettemps;
     if first_temps=0 then first_temps:=temps;
     if temps-first_temps>=1000 then
     begin
      intro2;
      first_temps:=0;
      intro;
     end;
     if qteclapuls then tecla:=agarrartecla;
    until (tecla=keyenter) or (tecla=keyesc);
    restore_color;
    num_fase:=1;
    if num_fase=1 then avio.bombes:=0;
    setup_game;
    if tecla<>keyesc then
    repeat
     info_mission(num_fase);
     inv:=0;
     {----------------Pantalla general----------------}
     repeat
      tecla:=$00;
      gestio_pantalla;
      if timer>0 then
         begin
          pinta_mission;
          pinta_num_mission(num_fase);
          dec(timer)
         end
      else
       begin
        moure_malo(avio_malo,avio,ammo_mala);
        test_malo(avio_malo);
        pinta_malos(avio_malo,vaddr2,off_avio,virt_vga);
       end;
      gestiona_bales(ammo,-1);  {-1 les bales van cap amunt les del bo}
      gestiona_bales(ammo_mala,1); {1 les bales van cap abaix le dels malos}
      gestiona_explosions;
      if qteclapuls then tecla:=agarrartecla;
      if mode_auto=0 then gestiona_avio(tecla,avio,ammo,ultima_tecla);
      if (avio.invencible=1) and (no_pintar=0) then pinta_escut;
      test_bales(ammo,-1);   {-1 les bales van cap amunt les del bo}
      test_bales(ammo_mala,1); {1 les bales van cap abaix le dels malos}
      if timer=0 then gestiona_mort_malos(avio_malo);
      gestiona_mort(mode_auto);
      pinta_bombes;
      pinta_vides;
      espera_vga;
      textcolor(15);
      volcar_pantalla(virt_vga,$a000);
      ultima_tecla:=tecla;
      inc(linies);
      linies:=linies mod 200;
{-->} {avio.invencible:=1;}
{-->} if tecla=keyf9 then kills:=fase_kills;
     until (tecla=keyesc) or (kills>=fase_kills) or (vides=0);
     {--------------Fi de pantalla general---------------------}

     if tecla=keyesc then fadedown(0,0,0,1);
     v_scroll1:=v_scroll1*2;
     v_scroll2:=v_scroll2*2;

     select_boss;
     defeated:=0;
     inicia_municio(ammo);
     inicia_municio(ammo_mala);
     timer:=100;
     {-------------------Pantalla del Boss----------------------}
     repeat
     if tecla<>keyesc then
      tecla:=$00;
      gestio_pantalla_boss;
      if timer>0 then dec(timer) else moure_boss_fase;
      gestiona_bales(ammo,-1);
      gestiona_bales(ammo_mala,1); {1 les bales van cap abaix le dels malos}
      gestiona_explosions;
      if qteclapuls then tecla:=agarrartecla;

      if mode_auto=0 then gestiona_avio(tecla,avio,ammo,ultima_tecla);
      if (avio.invencible=1) and (no_pintar=0) then pinta_escut;
      test_bales(ammo,-1);
      test_bales(ammo_mala,1); {1 les bales van cap abaix le dels malos}
      if timer=0 then gestiona_mort_boss_fase;
      gestiona_mort(mode_auto);
      pinta_bombes;
      pinta_vides;
      espera_vga;
      volcar_pantalla(virt_vga,$a000);
      ultima_tecla:=tecla;
{-->} if tecla=keynumlock then inv:=1;
      if inv=1 then avio.invencible:=1;
      inc(linies);
      linies:=linies mod 100;
     until (vides=0) or (tecla=keyesc) or (defeated=1);
     {--------------------Fi de pantalla del boss--------------------}
     if vides>0 then
     begin
      inc(num_fase);
      setup_fase(num_fase);
      inicia_municio(ammo);
      inicia_municio(ammo_mala);
     end;
     if (vides=0) or (num_fase=6) then
      begin
       setup_virtual(vscr_mort,vaddr_mort);
       load_pcx('mort.pcx',vaddr_mort);
       put_sprite(vaddr_mort,$a000,0,320,200,0,0);
       espera(3);
       tancar_virtual(vscr_mort);
       fadedown(0,0,0,1);
      end;
    until (tecla=keyesc) or (vides=0) or (num_fase=6);
    {desinstalarkb;}
    setmode($3);
    fi_joc;
  until tecla=keyesc;
  desinstalarkb;
end.