-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Calendar;
with Ada.Command_Line;

package Users is
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;

	type Message_Type is (Init, Welcome, Writer, Server, Logout);
	type Mult_Client is limited private;	
	
	procedure Welcome_Message(Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type);

	procedure Writer_Message(Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type);
	
	procedure Logout_Message(Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type);

private

	MaxClients: Integer := Integer'Value(ACL.Argument(2));
	type Client is record
		Client_EP: LLU.End_Point_Type;
		Nick_Name: ASU.Unbounded_String;
		Hour: Ada.Calendar.Time;
		Empty: Boolean := True;
	end record;
	type Mult_Client is array (1..50) of Client;

end;
