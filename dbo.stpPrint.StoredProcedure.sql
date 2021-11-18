USE [dbUniaoEQM]
GO
/****** Object:  StoredProcedure [dbo].[stpPrint]    Script Date: 17/11/2021 23:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Create the stored procedure in the specified schema
CREATE   PROCEDURE [dbo].[stpPrint]
    @texto VARCHAR(max)= 'Passou Aqui'
AS
BEGIN
    set @texto = @texto + ' - ' + convert(varchar,getdate(),121)
    raiserror(@texto, 10,1)     
END
GO
