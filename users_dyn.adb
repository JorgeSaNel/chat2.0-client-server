-- Jorge Santos Neila
-- Doble Grado en Sist. Telecomunicación + ADE

with Ada.Text_IO; use Ada.Text_IO;
with Unchecked_Deallocation;

package body Users is
	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	use type Ada.Calendar.Time;
	Num_Clients: Integer := 0;
	Nick_Server: ASU.Unbounded_String := ASU.To_Unbounded_String("Servidor");

	procedure Send_To_Clients (Client_EP: LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type; Nick, Message: ASU.Unbounded_String) is
	begin
		Message_Type'Output(P_Buffer, Server);
		ASU.Unbounded_String'Output(P_Buffer, Nick);
		ASU.Unbounded_String'Output(P_Buffer, Message);
		LLU.Send(Client_EP, P_Buffer);
	end Send_To_Clients;

	procedure Add_Client(P_Client: in out Mult_Client; EP_Handler: LLU.End_Point_Type; Nick: ASU.Unbounded_String) is
		New_Client:Mult_Client;
	begin
		New_Client := new Client;
		New_Client.Client_EP := EP_Handler;
		New_Client.Nick_Name := Nick;
		New_Client.Hour := Ada.Calendar.Clock;
		New_Client.Next := P_Client;
		P_Client := New_Client;

		Num_Clients := Num_Clients + 1;
	end Add_Client;

	procedure Free is new Unchecked_Deallocation (Client, Mult_Client);
	
	procedure Remove_Client(P_Client, P_Elem: in out Mult_Client) is
		P_Scan: Mult_Client;
	begin
		if P_Elem = P_Client then
	    	P_Client := P_Client.Next;
	        Free(P_Elem);
	    else
	        P_Scan := P_Client;
	        while P_Scan.Next /= P_Elem loop
	    	   	P_Scan := P_Scan.Next;
	        end loop;
	        P_Scan.Next := P_Elem.Next;
	    	Free(P_Elem);
        end if;

		Num_Clients := Num_Clients - 1;
	end Remove_Client;
	
	procedure Search_Send_Client_Remove (P_Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is
		Minor: Ada.Calendar.Time := P_Client.Hour;
		Message: ASU.Unbounded_String;
		P_Scan: Mult_Client;
		P_Elem: Mult_Client; --P_Elem will be remove
	begin
		P_Scan := P_Client;
		while P_Scan /= null loop
			if Minor > P_Scan.Hour then
				Minor := P_Scan.Hour;
				P_Elem := P_Scan;
			end if;
			P_Scan := P_Scan.Next;
		end loop;
		
		-- It send to all clients who will be remove
		P_Scan := P_Client;
		while P_Scan /= null loop
			if P_Scan.Nick_Name /= P_Elem.Nick_Name then
				LLU.Reset(P_Buffer.all);
				Message := ASU.To_Unbounded_String(ASU.To_String(P_Elem.Nick_Name) & " ha sido expulsado del chat");
				Send_To_Clients(P_Scan.Client_EP, P_Buffer, Nick_Server, Message);
			else
				LLU.Reset(P_Buffer.all);
				Message := ASU.To_Unbounded_String("has sido expulsado del chat");
				Send_To_Clients(P_Elem.Client_EP, P_Buffer, Nick_Server, Message);
			end if;
			P_Scan := P_Scan.Next;
		end loop;
		
		Remove_Client(P_Client, P_Elem);
	end Search_Send_Client_Remove; 
	
	function Admitted_Client (P_Client: Mult_Client; Nick: ASU.Unbounded_String) return Boolean is
		Admitted: Boolean := True;
		P_Scan: Mult_Client;
	begin
		P_Scan := P_Client;
		while P_Scan /= null loop
			if P_Scan.Nick_Name = Nick then
				Admitted := False;
				exit;
			end if;
			P_Scan := P_Scan.Next;
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
	
	------- Procedures WRITER -------
	-------------------------------
	procedure Welcome_Message(Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is 
		C_EP_Receive, C_EP_Handler: LLU.End_Point_Type;
		Nick_Name, Message: ASU.Unbounded_String;
		Admitted: Boolean := True;

		P_Scan: Mult_Client;
	begin
		--Get out from Buffer
		C_EP_Receive := LLU.End_Point_Type'Input(P_Buffer);
		C_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		Nick_Name := ASU.Unbounded_String'Input(P_Buffer);

		Admitted := Admitted_Client(Client, Nick_Name); -- Check if its a valid client
		if Admitted then
			if Num_Clients = MaxClients then
				Search_Send_Client_Remove(Client, P_Buffer);
			end if;
			
			LLU.Reset(P_Buffer.all);
			--Send to all clients who is new
			P_Scan := Client;
			Message := ASU.To_Unbounded_String(ASU.To_String(Nick_Name) & " ha entrado en el chat");
			while P_Scan /= null loop
				Send_To_Clients(P_Scan.Client_EP, P_Buffer, Nick_Server, Message);
				P_Scan := P_Scan.Next;
			end loop;

			Add_Client(Client, C_EP_Handler, Nick_Name);
		end if;

		Print_Admitted(Nick_Name, Admitted);
		Send_Admitted(P_Buffer, Admitted, C_EP_Receive);
	end Welcome_Message;


	------- Procedures WRITER -------
	---------------------------------
	procedure Writer_Message (Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is
		P_Scan: Mult_Client;
		Extrac_EP: LLU.End_Point_Type;
		Message, Nick_Name: ASU.Unbounded_String;
	begin
		Extrac_EP := LLU.End_Point_Type'Input(P_Buffer);
		Message := ASU.Unbounded_String'Input(P_Buffer);

		P_Scan := Client;
		while P_Scan /= null loop
			if P_Scan.Client_EP = Extrac_EP then
				P_Scan.Hour := Ada.Calendar.Clock;
				Nick_Name := P_Scan.Nick_Name;
				Put_Line("Recibido mensaje de " & ASU.To_String(Nick_Name) & ": " & ASU.To_String(Message));
				exit;
			end if;
			P_Scan := P_Scan.Next;
		end loop;

		P_Scan := Client;
		LLU.Reset(P_Buffer.all);
		while P_Scan /= null loop
			if P_Scan.Nick_Name /= Nick_Name and ASU.To_String(Nick_Name) /= "" then
				Send_To_Clients(P_Scan.Client_EP, P_Buffer, Nick_Name, Message);
			end if;
			P_Scan := P_Scan.Next;
		end loop;
	end Writer_Message;

	------- Procedures LOGOUT -------
	---------------------------------
	procedure Logout_Message (Client: in out Mult_Client; P_Buffer: access LLU.Buffer_Type) is
		C_EP_Handler: LLU.End_Point_Type;
		Message: ASU.Unbounded_String;
		P_Scan, P_Aux: Mult_Client;
	begin 
		C_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);

		P_Scan := Client;
		while P_Scan /= null loop
			if P_Scan.Client_EP = C_EP_Handler then
				Put_Line("Recibido mensaje de salida de " & ASU.To_String(P_Scan.Nick_Name));

				LLU.Reset(P_Buffer.all);				
				Message := ASU.To_Unbounded_String(ASU.To_String(P_Scan.Nick_Name) & " ha abandonado el chat");
				P_Aux := Client;
				while P_Aux /= null loop
					if P_Aux.Nick_Name /= P_Scan.Nick_Name then
						Send_To_Clients(P_Aux.Client_EP, P_Buffer, Nick_Server, Message);
					end if;
					P_Aux := P_Aux.Next;
				end loop;
			
				Remove_Client(Client, P_Scan);
				exit;
			end if;
			P_Scan := P_Scan.Next;
		end loop;
	end Logout_Message;
end;
