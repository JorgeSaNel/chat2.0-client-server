-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Users;

package body Handlers is
	package ASU renames Ada.Strings.Unbounded;
	use type ASU.Unbounded_String;

	procedure Client_Handler (From: in LLU.End_Point_Type; To: in LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type) is
		Nick_Name, Message: ASU.Unbounded_String;
		Mess: Users.Message_Type;
	begin
		-- Get out from P_Buffer
		Mess := Users.Message_Type'Input(P_Buffer);
		Nick_Name := ASU.Unbounded_String'Input(P_Buffer);
		Message := ASU.Unbounded_String'Input(P_Buffer);

		Ada.Text_IO.New_Line;
		Ada.Text_IO.Put_Line(ASU.To_String(Nick_Name) & ": " & ASU.To_String(Message));
   		Ada.Text_IO.Put(">> ");
	end Client_Handler;

end Handlers;
