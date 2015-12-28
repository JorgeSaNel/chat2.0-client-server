-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Text_IO;
with Ada.Command_Line;
with Ada.Exceptions;

with Lower_Layer_UDP;
with Handlers;
with Users;
procedure Chat_Client_2 is
	package LLU renames Lower_Layer_UDP;
	package ASU renames Ada.Strings.Unbounded;
	use type ASU.Unbounded_String;

	Nick_Name_Error: exception;
	Port_Error: exception;
	Usage_Error: exception;

	procedure Arguments_Input (Dir_Ip: out ASU.Unbounded_String; Port: out Natural; Nick_Name: out ASU.Unbounded_String) is
		package ACL renames Ada.Command_Line;
	begin
		if ACL.Argument_Count = 3 then
			Dir_IP := ASU.To_Unbounded_String(ACL.Argument(1));
			Dir_IP := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Dir_IP)));
			Port := Integer'Value(ACL.Argument(2));
			Nick_Name := ASU.To_Unbounded_String(ACL.Argument(3));

			if Nick_Name = "servidor" then
				raise Nick_Name_Error;
			elsif Port < 1024 or Port > 65535 then
				raise Port_Error;
			end if;
		else
			raise Usage_Error;
		end if;
	end Arguments_Input;

	procedure Read_String (Strings : out ASU.Unbounded_String) is
		package ASU_IO renames Ada.Strings.Unbounded.Text_IO;
	begin
		Put(">> ");
		Strings := ASU_IO.Get_Line;
	end Read_String;

	procedure Check_Client_Admitted(C_EP_Receive: LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type;
									Nick_Name: ASU.Unbounded_String; Admitted: in out Boolean) is
		Expired: Boolean;
		Mess: Users.Message_Type;
	begin
		LLU.Receive(C_EP_Receive, P_Buffer, 10.0, Expired);
		if Expired then
			Put_Line("No es posible comunicarse con el servidor");
			Admitted := False;
		else
			Mess := Users.Message_Type'Input(P_Buffer);
			Admitted := Boolean'Input(P_Buffer);
			if Admitted then
				Put_Line("Mini-Chat v2.0: Bienvenido " & ASU.To_String(Nick_Name));			
			else
				Put_Line("Mini-Chat v2.0: Cliente rechazado porque el nickname " & ASU.To_String(Nick_Name) & 
						 " ya existe en este servidor");
				Admitted := False;
			end if;
		end if;
	end Check_Client_Admitted;

	Server_EP: LLU.End_Point_Type;
	Client_EP_Receive: LLU.End_Point_Type;
	Client_EP_Handler: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);

	Dir_IP, Nick_Name: ASU.Unbounded_String;
	Port: Natural;
	Message: ASU.Unbounded_String;
	Admitted: Boolean := True;
begin
	begin
		Arguments_Input(Dir_Ip, Port, Nick_Name);

		Server_EP := LLU.Build(ASU.To_String(Dir_IP), Port); --Build End_Point in which the server is bound
		LLU.Bind_Any (Client_EP_Receive); --Build a free End_Point
		LLU.Bind_Any (Client_EP_Handler, Handlers.Client_Handler'Access); --Build a free Handler.End_Point

		-- Introduce Data into Buffer
		Users.Message_Type'Output(Buffer'Access, Users.Init);
		LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Receive);
		LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
		ASU.Unbounded_String'Output(Buffer'Access, Nick_Name);		
		LLU.Send(Server_EP, Buffer'Access); --Send it to the Server

		Check_Client_Admitted(Client_EP_Receive, Buffer'Access, Nick_Name, Admitted);
	
		if Admitted then
			loop
				LLU.Reset(Buffer);
	
				Read_String(Message);
				if ASU.To_String(Message) /= ".salir" then
					Users.Message_Type'Output(Buffer'Access, Users.Writer); 
					LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
					ASU.Unbounded_String'Output(Buffer'Access, Message);
				else
					Users.Message_Type'Output(Buffer'Access, Users.Logout); 
					LLU.End_Point_Type'Output(Buffer'Access, Client_EP_Handler);
				end if;
				LLU.Send(Server_EP, Buffer'Access);				
				exit when ASU.To_String(Message) = ".salir";
			end loop;
		end if;
	exception
		when Usage_Error =>
			Put_Line("Argumentos incorrectos");
		when Nick_Name_Error =>
			Put_Line("Mini-Chat v2.0: Cliente rechazado porque el nickname servidor no es valido");
		when Port_Error =>
			Put_Line("Puerto invalido");
	end;
	LLU.Finalize;
end;
