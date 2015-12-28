-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Text_IO; use Ada.Text_IO;

package body Users is
	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type Ada.Calendar.Time;
	Num_Clients: Integer := 0;
	Nick_Server: ASU.Unbounded_String := ASU.To_Unbounded_String("Servidor");

	procedure Send_To_Clients(N_Client_EP: LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type; Nick, Message: ASU.Unbounded_String) is
	begin
		Message_Type'Output(P_Buffer, Server);
		ASU.Unbounded_String'Output(P_Buffer, Nick);
		ASU.Unbounded_String'Output(P_Buffer, Message);
		LLU.Send(N_Client_EP, P_Buffer);
	end Send_To_Clients;
	
	-- Change the values of that who is in the last position for that who leaves the program
	procedure Change_Values (N_Client: in out Mult_Client; I:Integer) is
	begin
		N_Client(I).Client_EP := N_Client(Num_Clients).Client_EP;
		N_Client(I).Nick_Name := N_Client(Num_Clients).Nick_Name;
		N_Client(I).Hour := N_Client(Num_Clients).Hour;
		N_Client(Num_Clients).Empty := True;
	end Change_Values;

	------- Procedures INIT -------
	-------------------------------
	procedure Kick_Out_Client (N_Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is
		-- Very high number for expel the client with more time without writing
		Minor: Ada.Calendar.Time := N_Client(1).Hour + Duration(1000000);
		Message: ASU.Unbounded_String;
		j: integer;
	begin
		for I in 1..Num_Clients loop
			if Minor > N_Client(I).Hour then
				Minor := N_Client(I).Hour;
				j := i;
			end if;
		end loop;
		
		for I in 1..Num_Clients loop
			if N_Client(I).Nick_Name /= N_Client(j).Nick_Name then
				LLU.Reset(P_Buffer.all);
				Message := ASU.To_Unbounded_String(ASU.To_String(N_Client(j).Nick_Name) & " ha sido expulsado del chat");
				Send_To_Clients(N_Client(I).Client_EP, P_Buffer, Nick_Server, Message);
			else
				LLU.Reset(P_Buffer.all);
				Message := ASU.To_Unbounded_String("has sido expulsado del chat");
				Send_To_Clients(N_Client(j).Client_EP, P_Buffer, Nick_Server, Message);
			end if;
		end loop;

		Change_Values(N_Client, j);
	end Kick_Out_Client;

	function Admitted_Client (N_Client: Mult_Client; Nick: ASU.Unbounded_String) return Boolean is
		Admitted: Boolean := True;
	begin
		for I in 1..Num_Clients loop
			if N_Client(I).Nick_Name = Nick then
				Admitted := False;
				exit;
			end if;
		end loop;
		return Admitted;
	end Admitted_Client;

	procedure Print_Admitted (Nick: ASU.Unbounded_String; Admitted: Boolean) is
	begin
		Put("Recibido mensaje inicial de " & ASU.To_String(Nick) & ": ");
		if Admitted then
			Put_Line("ACEPTADO");
		else
			Put_Line("RECHAZADO");
		end if;
	end Print_Admitted;

	procedure Send_Admitted (P_Buffer: access LLU.Buffer_Type; Admitted: Boolean; EP_Receive: LLU.End_Point_Type) is
	begin
		LLU.Reset(P_Buffer.all);
		Message_Type'Output(P_Buffer, Welcome);
		Boolean'Output(P_Buffer, Admitted);
		LLU.Send(EP_Receive, P_Buffer);
	end Send_Admitted;

	procedure Welcome_Message(Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is 
		C_EP_Receive, C_EP_Handler: LLU.End_Point_Type;
		Nick_Name, Message: ASU.Unbounded_String;
		Admitted: Boolean := True;
	begin
		--Get out from Buffer
		C_EP_Receive := LLU.End_Point_Type'Input(P_Buffer);
		C_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		Nick_Name := ASU.Unbounded_String'Input(P_Buffer);

		Admitted := Admitted_Client(Client, Nick_Name); -- Check if its a valid client
		if Admitted then
			if Num_Clients = MaxClients then -- If the Array is full, its expels a client
				Kick_Out_Client(Client, P_Buffer);
				Num_Clients := Num_Clients - 1;
			end if;

			-- Send to all clients who is new
			LLU.Reset(P_Buffer.all);
			Message := ASU.To_Unbounded_String(ASU.To_String(Nick_Name) & " ha entrado en el chat");
			for I in 1..Num_Clients loop
				Send_To_Clients(Client(I).Client_EP, P_Buffer, Nick_Server, Message);
			end loop;

			Num_Clients := Num_Clients + 1;
			for I in 1..Num_Clients loop
				if Client(I).Empty then --Introduce Data on the correct arrays position
					Client(I).Client_EP := C_EP_Handler;
					Client(I).Nick_Name := Nick_Name;
					Client(I).Hour := Ada.Calendar.Clock;
					Client(I).Empty := False;
					exit;
				end if;
			end loop;
		end if;

		Print_Admitted(Nick_Name, Admitted);
		Send_Admitted(P_Buffer, Admitted, C_EP_Receive);
	end Welcome_Message;

	------- Procedures WRITER -------
	---------------------------------
	procedure Writer_Message (Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is
		Extrac_EP: LLU.End_Point_Type;
		Message, Nick_Name: ASU.Unbounded_String;
	begin
		Extrac_EP := LLU.End_Point_Type'Input(P_Buffer);
		Message := ASU.Unbounded_String'Input(P_Buffer);

		for I in 1..Num_Clients loop
			if Client(I).Client_EP = Extrac_EP then
				Client(I).Hour := Ada.Calendar.Clock;
				Nick_Name := Client(I).Nick_Name;
				Put_Line("Recibido mensaje de " & ASU.To_String(Nick_Name) & ": " & ASU.To_String(Message));
				exit;
			end if;
		end loop;

		LLU.Reset(P_Buffer.all);
		for I in 1..Num_Clients loop
			if Client(I).Nick_Name /= Nick_Name and ASU.To_String(Nick_Name) /= "" then
				Send_To_Clients(Client(I).Client_EP, P_Buffer, Nick_Name, Message);
			end if;
		end loop;
	end Writer_Message;


	------- Procedures LOGOUT -------
	---------------------------------
	procedure Logout_Message (Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is
		C_EP_Handler: LLU.End_Point_Type;
		Message: ASU.Unbounded_String;
	begin
		C_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		for I in 1..Num_Clients loop
			if Client(I).Client_EP = C_EP_Handler then
				Put_Line("Recibido mensaje de salida de " & ASU.To_String(Client(I).Nick_Name));

				LLU.Reset(P_Buffer.all);				
				Message := ASU.To_Unbounded_String(ASU.To_String(Client(I).Nick_Name) & " ha abandonado el chat");
				for J in 1..Num_Clients loop
					if Client(J).Nick_Name /= Client(I).Nick_Name then
						Send_To_Clients(Client(J).Client_EP, P_Buffer, Nick_Server, Message);
					end if;
				end loop;

				Change_Values(Client, I);
				Num_Clients := Num_Clients - 1;
				exit;
			end if;
		end loop;
	end Logout_Message;
end;
