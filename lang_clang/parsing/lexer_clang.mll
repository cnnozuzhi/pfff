{
(* Yoann Padioleau
 *
 * Copyright (C) 2013 Facebook
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1 as published by the Free Software Foundation, with the
 * special exception on linking described in file license.txt.
 * 
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
 * license.txt for more details.
 *)
open Common 

open Parser_clang
module Flag = Flag_parsing_clang

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

exception Lexical of string

let tok     lexbuf  = 
  Lexing.lexeme lexbuf

}
(*****************************************************************************)

let letter = ['A'-'Z' 'a'-'z']
let digit  = ['0'-'9']

let upper_letter = ['A'-'Z']
let lower_letter = ['a'-'z']

let newline = '\n'
let space = [' ' '\t']

let hexdigit = digit | ['a'-'f'] | ['A'-'F']

let operator = ['!' '%' '&' '*' '+' '-' '/' '<' '=' '>' '^' '|' '~']

let hexinteger = '0' ('x' | 'X') hexdigit+

let dec = ['0'-'9']
let pent   = dec+
let pfract = dec+
let sign = ['-' '+']
let exp  = ['e''E'] sign? dec+
let real = pent exp | ((pent? '.' pfract | pent '.' pfract? ) exp?)

(*****************************************************************************)


rule token = parse

  (* ----------------------------------------------------------------------- *)
  (* spacing/comments *)
  (* ----------------------------------------------------------------------- *)

  | "Processing:" [^'\n']+ { token lexbuf }
  | newline { token lexbuf }
  | space+ { token lexbuf }

  (* ----------------------------------------------------------------------- *)
  (* symbols *)
  (* ----------------------------------------------------------------------- *)
  | "(" { TOPar } | ")" { TCPar }
  | "<" { TInf } | ">" { TSup }
  | "[" { TOBracket } | "]" { TCBracket }

  | ":" { TColon } | "," { TComma }
  | "->" { TArrow } | "." { TDot } | "..." { TDots }
  | "=" { TEq }
  | "+" { TPlus } | "-" { TMinus }
  | "~" { TTilde } 
  | "*" { TStar } | "&" { TAnd }
      
  (* ----------------------------------------------------------------------- *)
  (* Keywords and ident *)
  (* ----------------------------------------------------------------------- *)
  | upper_letter (letter | digit | '_')* { TUpperIdent (tok lexbuf) }
  | (letter | '_') (letter | '_' | digit | '$')* { TLowerIdent (tok lexbuf) }
  | "built-in" 
  | "Getter&Setter"
      { TMisc (tok lexbuf) }
  | "operator" operator+
      { TMisc (tok lexbuf) }

  (* ----------------------------------------------------------------------- *)
  (* Constant *)
  (* ----------------------------------------------------------------------- *)
  | digit+ { TInt (tok lexbuf) }
  | hexinteger { THexInt (tok lexbuf) }
  | real { TFloat (tok lexbuf) }

  (* ----------------------------------------------------------------------- *)
  (* Strings *)
  (* ----------------------------------------------------------------------- *)
  | "'" [^'\'' ]* "'" { TString (tok lexbuf) }

  | '"' [^'\n']* '"' { TString (tok lexbuf) }

  | '/' [^ ':']* { TPath(tok lexbuf) }

  (* ----------------------------------------------------------------------- *)
  (* eof *)
  (* ----------------------------------------------------------------------- *)

  | eof { EOF }

  | _ { 
      if !Flag.verbose_lexing 
      then pr2_once ("LEXER:unrecognised symbol, in token rule:"^tok lexbuf);
      (* TUnknown (tok lexbuf) *)
      raise (Lexical (tok lexbuf))
    }

(*****************************************************************************)
