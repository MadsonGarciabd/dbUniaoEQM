USE [dbUniaoEQM]
GO
/****** Object:  StoredProcedure [Cadastros].[stpMantemContatoPessoa]    Script Date: 17/11/2021 23:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*------------------------------------------------------------
Autor      : Madson Garcia
Objeto     : stpMantemContatoPessoa
Objetivo   : Atualiza os dados de contato das pessoas
Impacto    : Tabela Cadastros.tPessoa
Regras     : A procedure retorna 0 em caso de sucesso
             em caso de erro retorna o id da tabela de log
--------------------------------------------------------------
Data            Resposável                   Alteração
09/10/2021      Madson Garcia                Criação
------------------------------------------------------------*/
CREATE   PROCEDURE [Cadastros].[stpMantemContatoPessoa]
    @cAcao                      CHAR                ='U'
    ,@iIdContato			    int                 = -1
	,@iIdPessoaFK				int				    = -1
	,@iIdTipoContatoFK			int				    = -1
	,@vContato					varchar(50)         = 'Desconhecido'
	,@vAssinatura				varchar(50)         = 'Desconhecido'
    ,@vCargoContato              VARCHAR(50)        = 'Colaborador'
    ,@iOrdemContatoUEQM         int                 = -1
    ,@RETURN_VALUE              VARCHAR(50)         = '-1,0' OUTPUT
AS 
BEGIN
     
    BEGIN TRY
        set @RETURN_VALUE = '0,' + CONVERT(VARCHAR,@iIdContato)
        IF ((@cAcao = 'U') or (exists (select 1 from Cadastros.tContatoPessoa where iIdPessoaFK = @iIdPessoaFK and iOrdemContatoUEQM = @iOrdemContatoUEQM and iIdTipoContatoFK = @iIdTipoContatoFK)))
            and @vContato is not null
        BEGIN
            UPDATE ContatoPessoa
            set iIdPessoaFK	        =   @iIdPessoaFK
            ,iIdTipoContatoFK       =   @iIdTipoContatoFK
            ,vContato		        =   @vContato
            ,vAssinatura	        =   @vAssinatura
            ,vCargoContato          =   @vCargoContato
            ,iOrdemContatoUEQM      =   @iOrdemContatoUEQM
                
            FROM Cadastros.tContatoPessoa ContatoPessoa
            WHERE 1=1
            and (   ContatoPessoa.iIdPessoaFK             = @iIdPessoaFK
                    AND 
                    ContatoPessoa.iOrdemContatoUEQM       = @iOrdemContatoUEQM
                    AND
                    ContatoPessoa.iIdTipoContatoFK        = @iIdTipoContatoFK
                )
            OR
                (ContatoPessoa.iIdContato = @iIdContato)



            IF @@ROWCOUNT = 0 -- Caso id não seja encontrado força um erro para cair no Cath
                BEGIN
                    DECLARE @msg VARCHAR(100)
                    IF @iIdContato <> -1
                    BEGIN
                        set @msg = 'Advertência no Update!! IdPessoaFK ' + convert(varchar,@iIdPessoaFK) + 'OrdemContato: ' 
                                                + @iOrdemContatoUEQM + ' Não encotrado na tabela Cadastros.tContatoPessoa '
                    END
                    ELSE
                    begin 
                        set @msg = 'Advertência no Update!! Id ' + convert(varchar,@iIdContato)  + ' Não encotrado na tabela Cadastros.tContatoPessoa '
                    end 
                    raiserror(@msg,16,1)
                END
        END
        ELSE IF @cAcao = 'I' and @vContato is not null
        BEGIN
            INSERT INTO Cadastros.tContatoPessoa
            (iIdPessoaFK,iIdTipoContatoFK,vContato,vAssinatura,vCargoContato,iOrdemContatoUEQM)
            VALUES
            (@iIdPessoaFK,@iIdTipoContatoFK,@vContato,@vAssinatura,@vCargoContato,@iOrdemContatoUEQM)
            set @RETURN_VALUE = '0,' + convert(varchar,SCOPE_IDENTITY ())
        END
        ELSE IF @cAcao = 'D'
        BEGIN
            Delete contato 
            from Cadastros.tContatoPessoa Contato
            WHERE Contato.iIdContato = @iIdContato
            set @RETURN_VALUE = '0,' + convert(varchar,SCOPE_IDENTITY ())
        END 
        
    END TRY

    BEGIN CATCH
        If @@TRANCOUNT > 0 -- tem transação aberta? 
            Rollback 

        -- Capturou as informações de erro 
        Declare  @niIDEvento            int = 0 
                ,@vMensagem             varchar(2048) 
                ,@nErrorNumber          int             = ERROR_NUMBER()
                ,@cErrorMessage         varchar(200)    = ERROR_MESSAGE()
                ,@nErrorSeverity        tinyint         = ERROR_SEVERITY()
                ,@nErrorState           tinyint         = ERROR_STATE()
                ,@cErrorProcedure       varchar(128)    = ERROR_PROCEDURE()
                ,@nErrorLine            int =            ERROR_LINE()
        
        Set @vMensagem = FormatMessage('MsgID %d. %s. Severidade %d. Status %d. Procedure %s. Linha %d.',
                                        @nErrorNumber,@cErrorMessage,@nErrorSeverity ,@nErrorState,@cErrorProcedure ,@nErrorLine)
        
        Insert into Cadastros.tLOGEventos (vMensagem) values (@vMensagem) 
        set @RETURN_VALUE = convert(varchar,SCOPE_IDENTITY ())
        set @vMensagem = @vMensagem + ' idLog = ' + convert(varchar,@RETURN_VALUE)
        set @RETURN_VALUE = '-1,' + @RETURN_VALUE
        Raiserror(@vMensagem,10,1)
    END CATCH
    select @RETURN_VALUE

    
END
GO
