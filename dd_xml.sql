CREATE OR REPLACE PACKAGE dd_XML AS

  /*
  // +----------------------------------------------------------------------+
  // | dd_XML - XML to SQL procedure                                        |
  // +----------------------------------------------------------------------+
  // | Copyright (C) 2022       http://rasd.sourceforge.net                 |
  // +----------------------------------------------------------------------+
  // | This program is free software; you can redistribute it and/or modify |
  // | it under the terms of the GNU General Public License as published by |
  // | the Free Software Foundation; either version 2 of the License, or    |
  // | (at your option) any later version.                                  |
  // |                                                                      |
  // | This program is distributed in the hope that it will be useful       |
  // | but WITHOUT ANY WARRANTY; without even the implied warranty of       |
  // | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the         |
  // | GNU General Public License for more details.                         |
  // +----------------------------------------------------------------------+
  // | Author: Domen Dolar       <domendolar@users.sourceforge.net>         |
  // |Created : 28.12.2022 10:13:45                                         |
  // |Purpose : Create XML  for SQL ,...                                    |
  // +----------------------------------------------------------------------+
  */

  /*
  STATUS
  28.12.2022 - First version - Domen Dolar
  */

  
  function XML2SQL(pxml varchar2, prootelement varchar2) return varchar2;

END;

/
CREATE OR REPLACE PACKAGE BODY dd_XML AS

 
  function XML2SQL(pxml varchar2, prootelement varchar2) return varchar2 is

    i                 integer;
    j                 integer;
    vrootelement      varchar2(100) := substr(prootelement,
                                              instr(prootelement, '/', -1) + 1);
    v_xmlsqltemplate varchar2(32000);
    v_str             varchar2(32000);
    v_columns         varchar2(32000);
    v_element         varchar2(100);
    v_element_cel         varchar2(1000);
   v_atributi  varchar2(1000);
    v_ns varchar2(1000);
    v_xml xmltype;
  begin

if pxml is not null then

v_xml := xmltype(pxml);

v_xmlsqltemplate := '
   select  #COLUMNS# 
   from table (xmlsequence(extract(#XML#, ''//#ROOT#'' #NS#))) x
';
    ------------------------
    --READ ELEMENT DATA

v_str := substr(pxml , instr(pxml,'<'||vrootelement)+length(vrootelement)+1, instr(pxml,'</'||vrootelement||'>')-(instr(pxml,'<'||vrootelement)+length(vrootelement)+1) );

if instr(substr(v_str,1,instr(v_str,'>')),'xmlns') > 0 
   and REGEXP_COUNT(substr(v_str,1,instr(v_str,'>')), '<')=0 then

v_ns := ','''||trim(substr(v_str,1,instr(v_str,'>')-1))||'''';

end if;
v_str := substr(v_str , instr(v_str,'>')+1 );

    ------------------------
    -- PREPARE COLUMNS
--        extractvalue(value(a),'//Envelope/Party[@partyRole="sender"]/@partyType') DrzposType,
--        extract(value(a),'//Declaration') DeclarationXMLType
v_atributi := '';
v_element := '';
j := 1;
while substr(v_str,instr(v_str,'<')+1, instr(v_str,'>')-instr(v_str,'<')-1) is not null and j < 100 loop
v_element_cel := substr(v_str,instr(v_str,'<')+1, instr(v_str,'>')-instr(v_str,'<')-1);
if instr(v_element_cel, ' ') = 0 then
v_element := v_element_cel;
else
v_element := substr(v_element_cel,1,instr(v_element_cel,' ')-1);
v_atributi := trim(substr(v_element_cel,instr(v_element_cel,' ')+1));
end if;

if v_atributi is not null then
 i := 1;
 while  v_atributi is not null and i < 100 loop
  v_columns := v_columns || ', extractvalue(value(x),''//'||v_element||'/@'||substr(v_atributi,1,instr(v_atributi,'=')-1)||''' #NS#) '||v_element||'_'||substr(v_atributi,1,instr(v_atributi,'=')-1)||'';
  v_atributi := trim(substr(v_atributi,  instr(substr(v_atributi,1,instr(v_atributi, '="',1,2)),' ',-1)  ));
  i := i +1;
 end loop;
end if;
if instr( trim(substr(v_str , instr(v_str,'>')+1 , instr(v_str,'</'||v_element||'>')-instr(v_str,'>')-2)) , '</' )>0 then
--xmltype
  v_columns := v_columns || ', extract(value(x),''//'||v_element||''' #NS#) '||v_element||'XML';
else
  v_columns := v_columns || ', extractvalue(value(x),''//'||v_element||''' #NS#) '||v_element||'';
end if;
v_str := substr(v_str,instr(v_str,'</'||v_element||'>')+length(v_element)+3);
j := j +1;
end loop;

end if;
  
if v_columns is null or prootelement is null then 
return '';
else
    return replace(replace(replace(replace(v_xmlsqltemplate,
                                   '#ROOT#',
                                   prootelement),
                           '#COLUMNS#',
                           substr(v_columns, 2)),
                   '#XML#',
                   'xmltype(''' || pxml || ''')'),'#NS#', v_ns);
end if; 
  end;



END;
/

