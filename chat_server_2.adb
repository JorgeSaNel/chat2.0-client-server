-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Command_Line;

with Lower_Layer_UDP;
with Users;
procedure Chat_Server_2 is
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;
	use type Users.Message_Type;

	Usage_Error: exception;
	Port_Error: exception;
	Num_Clients_Error: exception;
	
	procedure Create_Server(Server_EP: in out LLU.End_Point_Type) is
		package ACL renames Ada.Command_Line;
		Host_Name: ASU.Unbounded_String;
		Port, Num_MaxClients: Natural;
	begin
		if ACL.Argument_Count = 2 then
			Host_Name := ASU.To_Unbounded_String(LLU.Get_Host_Name);
			Host_Name := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Host_Name)));
			Port := Integer'Value(ACL.Argument(1));
			Num_MaxClients := Integer'Value(ACL.Argument(2));
			
			if Port < 1024 or Port > 65535 then
				raise Port_Error;
			elsif Num_MaxClients < 2 or Num_MaxClients > 50 then
				raise Num_Clients_Error;
			else
				Server_EP := LLU.Build(ASU.To_String(Host_Name), Port);
				LLU.Bind (Server_EP);
			end if;
		else
			raise Usage_Error;
		end if;
	end Create_Server;
	
	Server_EP: LLU.End_Point_Type;
	Mult_Clients: Users.Mult_Client;
	Mess: Users.Message_Type;
	Buffer: aliased LLU.Buffer_Type(1024);
begin
	begin
		Create_Server(Server_EP);
		loop
			LLU.Reset(Buffer);
			LLU.Receive(Server_EP, Buffer'Access);
			Mess := Users.Message_Type'Input(Buffer'Access);
			if Mess = Users.Init then
				Users.Welcome_Message(Mult_Clients, Buffer'Access);
			elsif Mess = Users.Writer then
				Users.Writer_Message(Mult_Clients, Buffer'Access);
			elsif Mess = Users.Logout then
				Users.Logout_Message(Mult_Clients, Buffer'Access);
			end if;
		end loop;
	exception
		when Usage_Error =>
			Put_Line("Argumentos incorrectos");
			LLU.Finalize;
		when Port_Error =>
			Put_Line("Puerto invalido");
			LLU.Finalize;
		when Num_Clients_Error =>
			Put_Line("Numero de clientes invalido");
			LLU.Finalize;
	end;
end;
