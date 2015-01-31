unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, Data.Bind.Controls, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, System.Rtti, Fmx.Bind.Grid, System.Bindings.Outputs,
  Fmx.Bind.Editors, Data.Bind.Components, Data.Bind.Grid, FMX.Layouts, FMX.Grid,
  Fmx.Bind.Navigator, Data.Bind.DBScope, FireDAC.FMXUI.Wait, FireDAC.Comp.UI,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, FMX.StdCtrls,
  FMX.Memo, FMX.Controls.Presentation, FMX.Edit, IdIPMCastBase, IdIPMCastClient,
  IdAntiFreezeBase, Vcl.IdAntiFreeze,

  IdGlobal, System.DateUtils;

type
  TForm2 = class(TForm)
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    Grid1: TGrid;
    LinkGridToDataSourceBindSourceDB1: TLinkGridToDataSource;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    bStart: TButton;
    IdTCPClient1: TIdTCPClient;
    bStop: TButton;
    Memo1: TMemo;
    eServer: TEdit;
    Label1: TLabel;
    Timer1: TTimer;
    procedure bStartClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure bStopClick(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TByteArray = packed array[1..65536] of Byte;
  T3ByteArray = packed array[0..2] of Byte;

  //Формат подзаписи EGTS_SR_TERM_IDENTITY сервиса EGTS_AUTH_SERVICE
  TEGTS_SR_TERM_IDENTITY = packed record
    TID : LongWord;
    Flags : Byte; // MNE  BSE  NIDE  SSRA (Алгоритм "Простой"=1)  LNGCE  IMSIE  IMEIE  HDIDE
    //HDID (Home Dispatcher Identifier)  O  USHORT  2
    //IMEI (International Mobile Equipment Identity)  O  STRING  15
    //IMSI (International Mobile Subscriber Identity)  O  STRING  16
    //LNGC (Language Code)  O  STRING  3
    //NID (Network Identifier)  O  BINARY  3
    BS : Word; // Размер буфера АС
    //MSISDN (Mobile Station Integrated Services Digital Network Number) O  STRING  15
  end;

  //Формат подзаписи EGTS_SR_POS_DATA сервиса EGTS_TELEDATA_SERVICE
  TEGTS_SR_POS_DATA = packed record
    NTM : LongWord;
    LAT : LongWord;
    LONG : LongWord;
    FLG : Byte;
    SPD : Byte;
    DIRH_ALTS_SPD : Byte;
    DIR : Byte;
    ODM : T3ByteArray;
    DIN : Byte;
    SRC : Byte;
    ALT : T3ByteArray;
    SRCD : SmallInt;
  end;

  //Формат заголовка поля SFRD
  TSFRD = packed record
    RL : Word; // Длина RD - меняется в зависимости от типа
    RN : Word;
    RFL : Byte; // SSOD  RSOD  GRP  RPP(2 бита)  TMFE  EVFE  OBFE
    OID : LongWord;
    EVID : LongWord;
    TM : LongWord;
    SST : Byte; // Для сервиса EGTS_AUTH_SERVICE: EGTS_SR_TERM_IDENTITY=1
                // Для сервиса EGTS_TELEDATA_SERVICE: EGTS_SR_POS_DATA = 16
    RST : Byte; // Аналогично
  end;

  TRecSubRec = packed record
    Rec : TSFRD;
    SubRec : TEGTS_SR_POS_DATA;
  end;

  // Упрощение - сводная запись + заголовок подзаписи + 1 подзапись для координат
  TRecSubRec_EGTS_SR_POS_DATA = packed record
    RL : Word; // Длина RD - меняется в зависимости от типа
    RN : Word;
    RFL : Byte; // SSOD  RSOD  GRP  RPP(2 бита)  TMFE  EVFE  OBFE
    OID : LongWord;
//    EVID : LongWord;
//    TM : LongWord;
    SST : Byte; // Для сервиса EGTS_AUTH_SERVICE: EGTS_SR_TERM_IDENTITY=1
                // Для сервиса EGTS_TELEDATA_SERVICE: EGTS_SR_POS_DATA = 16
    RST : Byte; // Аналогично

    // Заголовок подзаписи
    SRT : Byte; // Тип подзаписи
    SRL : Word; // Длина подзаписи

    // Подзапись типа EGTS_SR_POS_DATA сервиса EGTS_TELEDATA_SERVICE
    NTM : LongWord;
    LAT : LongWord;
    LONG : LongWord;
    FLG : Byte;
    SPD : Byte;
    DIRH_ALTS_SPD : Byte;
    DIR : Byte;
    ODM : T3ByteArray;
    DIN : Byte;
    SRC : Byte;
    ALT : T3ByteArray;
    SRCD : SmallInt;
  end;
  TEGTS_Ar = packed array of TRecSubRec_EGTS_SR_POS_DATA;

  // Состав пакета протокола Транспортного уровня
  TProtocolRecord = packed record
    prv : Byte;
    skid : Byte;
    prefix : Byte;
    hl : Byte;
    he : Byte;
    fdl : Word;
    pid : Word;
    pt : Byte;
//    pra : Word;
//    rca : Word;
//    ttl : Byte;
    hcs : Byte;
    sfrd : TEGTS_Ar;
    sfrcs : Word;
  end;

  TAuto = record
    device : Integer;
    lrts : String;
  end;
  TAutoArray = array of TAuto;

const
  // Типы сервисов
  EGTS_AUTH_SERVICE = 1;
  EGTS_TELEDATA_SERVICE =2;

  // Список типов подзаписей сервиса EGTS_AUTH_SERVICE
  EGTS_SR_RECORD_RESPONSE = 0;
  EGTS_SR_TERM_IDENTITY = 1;
  EGTS_SR_MODULE_DATA = 2;
  EGTS_SR_VEHICLE_DATA = 3;
  EGTS_SR_AUTH_INFO = 7;
  EGTS_SR_SERVICE_INFO = 8;
  EGTS_SR_RESULT_CODE = 9;

  // Список типов подзаписей сервиса EGTS_TELEDATA_SERVICE
  //EGTS_SR_RECORD_RESPONSE - совпадает с EGTS_AUTH_SERVICE
  EGTS_SR_POS_DATA = 16;
  EGTS_SR_EXT_POS_DATA = 17;
  EGTS_SR_AD_SENSORS_DATA = 18;
  EGTS_SR_COUNTERS_DATA = 19;
  EGTS_SR_STATE_DATA = 20;
  EGTS_SR_LOOPIN_DAТА = 22;
  EGTS_SR_ABS_DIG_SENS_DATA = 23;
  EGTS_SR_ABS_AN_SENS_DATA = 24;
  EGTS_SR_ABS_CNTR_DATA = 25;
  EGTS_SR_ABS_LOOPIN_DATA = 26;
  EGTS_SR_LIQUID_LEVEL_SENSOR = 27;
  EGTS_SR_PASSENGERS_COUNTERS = 28;

  // Для счётчика
  FILENAME_COUNTER = 'counter.cnt';
  // Журнал
  FILENAME_LOG = 'data.log';
  // Команды журналу
  Rewrite_Log = '#REWRITE_LOG';

var
  Form2: TForm2;
  EgtsAr : TEGTS_Ar;
  Tcp : TProtocolRecord;
  NullArr3 : T3ByteArray = (0,0,0);
  TcpStream : TMemoryStream;
  Counter: Word;
  Auto : TAutoArray;
  Buf, BufH : TIdBytes;
  Executed : Boolean;
  AllRData : String;
  TF : TextFile;


implementation

{$R *.fmx}

procedure LoadCounter;
var
  f : file of Word;
begin
  if FileExists(FILENAME_COUNTER) then begin
    AssignFile(f, FILENAME_COUNTER);
    Reset(f);
    Read(f, Counter);
    CloseFile(f);
  end else
    Counter := 0;
end;

procedure SaveCounter;
var
  f: file of Word;
begin
  AssignFile(f, FILENAME_COUNTER);
  Rewrite(f);
  Write(f, Counter);
  CloseFile(f);
end;

procedure Log(S : String);
var
  H, M, Sec, Ms : Word;
begin
  AssignFile(TF, FILENAME_LOG);
  if S = Rewrite_Log then begin
    DecodeTime(Now, H, M, Sec, Ms);
    if (H = 0) and (M = 0) and (Sec*1000 < Form2.Timer1.Interval) then begin
      DeleteFile(FILENAME_LOG + '.YESTERDAY');
      Rename(TF, FILENAME_LOG + '.YESTERDAY');
    end;
    Exit;
  end;

  Form2.Memo1.Lines.Add(S);

  // Запись в журнал
  if FileExists(FILENAME_LOG) then begin
    Append(TF);
  end else begin
    Rewrite(TF);
  end;

  Writeln(TF, S);

  // Закрыть файл журнала
  Flush(TF);
  CloseFile(TF);
end;

const Crc16Table: array[0..255] of WORD = (
    $0000, $1021, $2042, $3063, $4084, $50A5, $60C6, $70E7,
    $8108, $9129, $A14A, $B16B, $C18C, $D1AD, $E1CE, $F1EF,
    $1231, $0210, $3273, $2252, $52B5, $4294, $72F7, $62D6,
    $9339, $8318, $B37B, $A35A, $D3BD, $C39C, $F3FF, $E3DE,
    $2462, $3443, $0420, $1401, $64E6, $74C7, $44A4, $5485,
    $A56A, $B54B, $8528, $9509, $E5EE, $F5CF, $C5AC, $D58D,
    $3653, $2672, $1611, $0630, $76D7, $66F6, $5695, $46B4,
    $B75B, $A77A, $9719, $8738, $F7DF, $E7FE, $D79D, $C7BC,
    $48C4, $58E5, $6886, $78A7, $0840, $1861, $2802, $3823,
    $C9CC, $D9ED, $E98E, $F9AF, $8948, $9969, $A90A, $B92B,
    $5AF5, $4AD4, $7AB7, $6A96, $1A71, $0A50, $3A33, $2A12,
    $DBFD, $CBDC, $FBBF, $EB9E, $9B79, $8B58, $BB3B, $AB1A,
    $6CA6, $7C87, $4CE4, $5CC5, $2C22, $3C03, $0C60, $1C41,
    $EDAE, $FD8F, $CDEC, $DDCD, $AD2A, $BD0B, $8D68, $9D49,
    $7E97, $6EB6, $5ED5, $4EF4, $3E13, $2E32, $1E51, $0E70,
    $FF9F, $EFBE, $DFDD, $CFFC, $BF1B, $AF3A, $9F59, $8F78,
    $9188, $81A9, $B1CA, $A1EB, $D10C, $C12D, $F14E, $E16F,
    $1080, $00A1, $30C2, $20E3, $5004, $4025, $7046, $6067,
    $83B9, $9398, $A3FB, $B3DA, $C33D, $D31C, $E37F, $F35E,
    $02B1, $1290, $22F3, $32D2, $4235, $5214, $6277, $7256,
    $B5EA, $A5CB, $95A8, $8589, $F56E, $E54F, $D52C, $C50D,
    $34E2, $24C3, $14A0, $0481, $7466, $6447, $5424, $4405,
    $A7DB, $B7FA, $8799, $97B8, $E75F, $F77E, $C71D, $D73C,
    $26D3, $36F2, $0691, $16B0, $6657, $7676, $4615, $5634,
    $D94C, $C96D, $F90E, $E92F, $99C8, $89E9, $B98A, $A9AB,
    $5844, $4865, $7806, $6827, $18C0, $08E1, $3882, $28A3,
    $CB7D, $DB5C, $EB3F, $FB1E, $8BF9, $9BD8, $ABBB, $BB9A,
    $4A75, $5A54, $6A37, $7A16, $0AF1, $1AD0, $2AB3, $3A92,
    $FD2E, $ED0F, $DD6C, $CD4D, $BDAA, $AD8B, $9DE8, $8DC9,
    $7C26, $6C07, $5C64, $4C45, $3CA2, $2C83, $1CE0, $0CC1,
    $EF1F, $FF3E, $CF5D, $DF7C, $AF9B, $BFBA, $8FD9, $9FF8,
    $6E17, $7E36, $4E55, $5E74, $2E93, $3EB2, $0ED1, $1EF0);

function GetCRC16(len : Word) : Word; // CCITT: полином x^16 + x^12 + x^5 + 1
var
  i : integer;
  crc : Word;
  P : ^TByteArray absolute egtsAr;
  data : Byte;
begin
  crc := $FFFF;
  for i := 1 to len do begin
     data := P^[i];
     crc := (crc shl 8) xor Crc16Table[(crc shr 8) xor data];
  end;

  result := crc;
end;

const Crc8Table: array[0..255] of Byte = (
    $00, $31, $62, $53, $C4, $F5, $A6, $97,
    $B9, $88, $DB, $EA, $7D, $4C, $1F, $2E,
    $43, $72, $21, $10, $87, $B6, $E5, $D4,
    $FA, $CB, $98, $A9, $3E, $0F, $5C, $6D,
    $86, $B7, $E4, $D5, $42, $73, $20, $11,
    $3F, $0E, $5D, $6C, $FB, $CA, $99, $A8,
    $C5, $F4, $A7, $96, $01, $30, $63, $52,
    $7C, $4D, $1E, $2F, $B8, $89, $DA, $EB,
    $3D, $0C, $5F, $6E, $F9, $C8, $9B, $AA,
    $84, $B5, $E6, $D7, $40, $71, $22, $13,
    $7E, $4F, $1C, $2D, $BA, $8B, $D8, $E9,
    $C7, $F6, $A5, $94, $03, $32, $61, $50,
    $BB, $8A, $D9, $E8, $7F, $4E, $1D, $2C,
    $02, $33, $60, $51, $C6, $F7, $A4, $95,
    $F8, $C9, $9A, $AB, $3C, $0D, $5E, $6F,
    $41, $70, $23, $12, $85, $B4, $E7, $D6,
    $7A, $4B, $18, $29, $BE, $8F, $DC, $ED,
    $C3, $F2, $A1, $90, $07, $36, $65, $54,
    $39, $08, $5B, $6A, $FD, $CC, $9F, $AE,
    $80, $B1, $E2, $D3, $44, $75, $26, $17,
    $FC, $CD, $9E, $AF, $38, $09, $5A, $6B,
    $45, $74, $27, $16, $81, $B0, $E3, $D2,
    $BF, $8E, $DD, $EC, $7B, $4A, $19, $28,
    $06, $37, $64, $55, $C2, $F3, $A0, $91,
    $47, $76, $25, $14, $83, $B2, $E1, $D0,
    $FE, $CF, $9C, $AD, $3A, $0B, $58, $69,
    $04, $35, $66, $57, $C0, $F1, $A2, $93,
    $BD, $8C, $DF, $EE, $79, $48, $1B, $2A,
    $C1, $F0, $A3, $92, $05, $34, $67, $56,
    $78, $49, $1A, $2B, $BC, $8D, $DE, $EF,
    $82, $B3, $E0, $D1, $46, $77, $24, $15,
    $3B, $0A, $59, $68, $FF, $CE, $9D, $AC);

function GetCRC8(S : String) : Byte; // CCITT: полином x^8 + x^5 + x^4 + 1
var
  i : integer;
  c : byte;
begin
   c := $FF;
   for i := 1 to length(S) do begin
     c := CRC8Table[c xor Byte(S[i])];
   end;
   result := c;
end;

procedure TForm2.bStartClick(Sender: TObject);
var
  i : Word;
begin
  AllRData := '';
  // Инициализация массива начальных данных
  IdTCPClient1.Host := eServer.Text;
  if not FDQuery1.Active then
    FDQuery1.Active := true
  else begin
    FDQuery1.First;
    FDQuery1.Refresh;
  end;

  i := 0;
  while not FDQuery1.Eof do begin
    SetLength(Auto, i+1);
    Auto[i].device := FDQuery1.FieldByName('device').AsInteger; // время в секундах с 01.01.2010 00:00 по Гринвичу
    Auto[i].lrts := FDQuery1.FieldByName('lrts').AsString;
    Inc(i);
    FDQuery1.Next;
  end;

  // Запуск таймера
  Timer1.Enabled := True;
  Log(DateTimeToStr(Now) + ' - Таймер включён');
  bStart.Enabled := False;
  bStop.Enabled := True;
end;

procedure TForm2.bStopClick(Sender: TObject);
begin
  // Остановка таймера
//  Log(AllRData);
  Timer1.Enabled := False;
  Log(DateTimeToStr(Now) + ' - Таймер остановлен');
  bStart.Enabled := True;
  bStop.Enabled := False;
  if IdTCPClient1.Connected then
    IdTCPClient1.Disconnect;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  bStartClick(self);
end;

procedure TForm2.Memo1Change(Sender: TObject);
const
  MaxLineCount = 100;
begin
  if Memo1.Lines.Count > MaxLineCount then
    Memo1.Lines.Delete(0);
end;

procedure TForm2.Timer1Timer(Sender: TObject);
var
  i, j, u, DataSize : Integer;
  cs_str, tcpstr, s : String;
  BufStream : array[0..16*1024] of Byte;
  rhcs : Byte;
  rsfrcs : Word;

  function Check : Boolean;
  var
    DevIsFound : Boolean;
    k : Integer;
  begin
    DevIsFound := False;
    Result := False;
    for k := 0 to High(Auto) do begin
      if Auto[k].device = FDQuery1.FieldByName('device').AsInteger then begin
        DevIsFound := True;
        if Auto[k].lrts = FDQuery1.FieldByName('lrts').AsString then
          Result := True
        else
          Auto[k].lrts := FDQuery1.FieldByName('lrts').AsString;
        Break;
      end;
    end;
    if not DevIsFound then begin
      SetLength(Auto, High(Auto)+2);
      Auto[High(Auto)].device := FDQuery1.FieldByName('device').AsInteger;
      Auto[High(Auto)].lrts := FDQuery1.FieldByName('lrts').AsString;
    end;
  end;

begin
  // Переименовать журнал и создать его заново, если начался новый день
  Log(Rewrite_Log);

  if Executed then
    Exit;

  try
    if not FDQuery1.Active then
      FDQuery1.Active := true
    else begin
      FDQuery1.First;
      FDQuery1.Refresh;
    end;
  except // Блок try добавлен 15.01.2015
    on E : Exception do begin
      Log(E.ClassName + ' вызвана ошибка, с сообщением : ' + E.Message);
      Exit;
    end;
  end;

  // Запуск TCP клиента, установление соединения
  Log('-------------------------------------------------------------------------');
  try
    if IdTCPClient1.Connected then begin
      // Добавлено 14.01.2015
      IdTCPClient1.Disconnect;
      IdTCPClient1.IOHandler.DiscardAll;
      IdTCPClient1.IOHandler.Close;
    end;
    IdTCPClient1.Connect;
    Log(DateTimeToStr(Now) + ' - Соединение с сервером ' + IdTCPClient1.Host + ':' + IntToStr(IdTCPClient1.Port) + ' установлено');
  except
    // Добавлено 14.01.2015
    on E : Exception do begin
      Log(E.ClassName + ' вызвана ошибка, с сообщением : ' + E.Message);
      Exit;
    end;
  end;

  Log(DateTimeToStr(Now) + ' - Начало передачи блока данных');
  try
    Executed := True;
    LoadCounter;

    while not FDQuery1.Eof do begin
      if Check then begin
        FDQuery1.Next;
        Continue;
      end;

      Inc(Counter);

      // Формируем массив записей с подзаписью типа EGTS_SR_POS_DATA
      i := 0;
      SetLength(egtsAr, i+1);
      with egtsAr[i] do begin
        // Запись
        RL := SizeOf(TEGTS_SR_POS_DATA) + SizeOf(SRT) + SizeOf(SRL); // !!!Длина RD - меняется в зависимости от типа
        RN := Counter;
        RFL := $81; // +SSOD  -RSOD  -GRP  --RPP(2 бита)  -TMFE  -EVFE  +OBFE
        OID := 22000000 + FDQuery1.FieldByName('device').AsInteger;
        SST := EGTS_TELEDATA_SERVICE;
        RST := EGTS_TELEDATA_SERVICE; // Аналогично

        // Заголовок подзаписи
        SRT := EGTS_SR_POS_DATA; // Тип подзаписи. Для сервиса EGTS_AUTH_SERVICE: EGTS_SR_TERM_IDENTITY=1
                    // Для сервиса EGTS_TELEDATA_SERVICE: EGTS_SR_POS_DATA = 16
        SRL := SizeOf(TEGTS_SR_POS_DATA); // !!! Длина подзаписи

        // Подзапись типа EGTS_SR_POS_DATA
        NTM := Round(FDQuery1.FieldByName('lrts').AsFloat / 1000) - 1262304000; // время в секундах с 01.01.2010 00:00 по Гринвичу
        LAT := Round(FDQuery1.FieldByName('lat').AsInteger/90*$FFFFFFFF);
        LONG := Round(FDQuery1.FieldByName('lng').AsInteger/180*$FFFFFFFF);
        FLG := 0;
        SPD := FDQuery1.FieldByName('speed').AsInteger;
        DIRH_ALTS_SPD := 0;
        DIR := 0;
        ODM := NullArr3;
        DIN := 0;
        SRC := 0;
        ALT := NullArr3;
        SRCD := 0;

        Inc(i);
      end;

      // Формируем запись для протокола TCP
      with tcp do begin
        prv := 1;
        skid := 0;
        prefix := 3;  // Флаги
        hl := 11; // длина заголовка, включая hcs
        he := 0;
        fdl := sizeof(TRecSubRec_EGTS_SR_POS_DATA)*i;
        pid := Counter;
        pt := 1; // тип пакета 1 - EGTS_PT_APPDATA (пакет, содержащий данные протокола Уровня поддержки услуг)
//        pra := 0;
//        rca := 0;
//        ttl := 0;
        cs_str :=
          Char(prv)+Char(skid)+Char(prefix)+Char(hl)+Char(he)+
          Char(fdl mod $100)+Char(fdl div $100)+
          Char(pid mod $100)+Char(pid div $100)+Char(pt)
//          +
//          Char(pra mod $100)+Char(pra div $100)+
//          Char(rca mod $100)+Char(rca div $100)+Char(ttl)
          ;
        hcs := GetCRC8(cs_str); // контрольная сумма CRC-8
        sfrd := egtsAr;
        sfrcs := GetCRC16(sizeof(TRecSubRec_EGTS_SR_POS_DATA)*i);
      end;

      // Формируем поток данных для протокола TCP на основе записи
      with tcp do begin
        TcpStream := TMemoryStream.Create;
        try
          DataSize := 0;

          // Формирование в потоке данных подзаписи типа EGTS_SR_POS_DATA
          TcpStream.Write(prv, SizeOf(prv)); Inc(DataSize, SizeOf(prv));
          TcpStream.Write(skid, SizeOf(skid)); Inc(DataSize, SizeOf(skid));
          TcpStream.Write(prefix, SizeOf(prefix)); Inc(DataSize, SizeOf(prefix));
          TcpStream.Write(hl, SizeOf(hl)); Inc(DataSize, SizeOf(hl));
          TcpStream.Write(he, SizeOf(he)); Inc(DataSize, SizeOf(he));
          TcpStream.Write(fdl, SizeOf(fdl)); Inc(DataSize, SizeOf(fdl));
          TcpStream.Write(pid, SizeOf(pid)); Inc(DataSize, SizeOf(pid));
          TcpStream.Write(pt, SizeOf(pt)); Inc(DataSize, SizeOf(pt));
//          TcpStream.Write(pra, SizeOf(pra)); Inc(DataSize, SizeOf(pra));
//          TcpStream.Write(rca, SizeOf(rca)); Inc(DataSize, SizeOf(rca));
//          TcpStream.Write(ttl, SizeOf(ttl)); Inc(DataSize, SizeOf(ttl));
          TcpStream.Write(hcs, SizeOf(hcs)); Inc(DataSize, SizeOf(hcs));

          // Заголовок SFRD

          for j := 0 to i-1 do begin
            TcpStream.Write(sfrd[j], SizeOf(sfrd[j]));
            Inc(DataSize, SizeOf(sfrd[j]));
          end;
          TcpStream.Write(sfrcs, SizeOf(sfrcs)); Inc(DataSize, SizeOf(sfrcs));
          TcpStream.Position := 0;

          TcpStream.Read(BufStream, TcpStream.Size);
          tcpstr := '';
          for u := 0 to TcpStream.Size - 1 do
            tcpstr := tcpstr + IntToHex(BufStream[u], 2);
          TcpStream.Position := 0;

          Log('Сформирован пакет: ');
          Log(tcpstr);

          try
            IdTCPClient1.IOHandler.Write(TcpStream); //tcp.hl + tcp.fdl + 2
          except
            on E : Exception do begin
              Log(E.ClassName + ' вызвана ошибка, с сообщением : ' + E.Message);
              Exit;
            end;
          end;

          Log(
            'Отправлен пакет: prv=' + IntToStr(prv) +
            ', skid=' + IntToStr(skid) +
            ', prefix=' + IntToStr(prefix) +
            ', hl=' + IntToStr(hl) +
            ', he=' + IntToStr(he) +
            ', fdl=' + IntToStr(fdl) +
            ', pid=' + IntToStr(pid) +
            ', hcs(полином 0x31)=0x' + ByteToHex(hcs) +
            ', sfrcs(полином 0x1021)=0x' + ByteToHex(sfrcs div $100) + ByteToHex(sfrcs)
          );
//          Log('Количество подзаписей типа EGTS_SR_POS_DATA: ' + IntToStr(i));
          Log(
            'Устройство: device=' + IntToStr(sfrd[0].OID) +
            ', lrts=' + FDQuery1.FieldByName('lrts').AsString
          );
          SaveCounter;

        finally
          TcpStream.Free;
        end;

        // Чтение ответа-подтверждения
        try
          SetLength(BufH, 0);
          SetLength(Buf, 0);
          IdTCPClient1.IOHandler.ReadBytes(BufH, 14, False);
          s := '';
          for j := 0 to Length(BufH)-1 do
            s := s + ByteToHex(BufH[j]);
//          AllRData := AllRData + s;
          Log(
            'Получено подтверждение о приёме на пакет: pid=' + IntToStr(BufH[12]*$100 + BufH[11]) +
            '; Код исполнения: ' + IntToStr(BufH[13]) +
            '; Длина записи: ' + IntToStr(BufH[6]*$100+BufH[5])
            );
          if BufH[6]*$100+BufH[5] > 1 then
            IdTCPClient1.IOHandler.ReadBytes(Buf, BufH[6]*$100+BufH[5]-1, False);
          for j := 0 to Length(Buf)-1 do
            s := s + ByteToHex(Buf[j]);
//          AllRData := AllRData + s;
          Log(s);
          // Проверка контрольной суммы HCS
          cs_str := '';
          for j := 0 to BufH[3]-2 do
            cs_str := cs_str + Char(BufH[j]);
          rhcs := GetCRC8(cs_str); // контрольная сумма CRC-8
          if rhcs = BufH[BufH[3]-1] then
            Log('Контрольная сумма HCS (CRC-8) совпадает и равна: 0x' + ByteToHex(rhcs))
          else
            Log('Контрольная сумма HCS = 0x' + ByteToHex(BufH[BufH[3]-1]) + '  ошибочна, должна быть: 0x' + ByteToHex(rhcs));

      //            IdTCPClient1.IOHandler.ReadBytes(Buf, -1, False);
        except
          Log('Первышено время жидания ответа на пакет: pid=' + IntToStr(pid));
        end;

      end;
      FDQuery1.Next;
    end;
  finally
    Log(DateTimeToStr(Now) + ' - Окончание передачи блока данных');
    Memo1.GoToTextEnd;
    Executed := False;

    // Добавлено 14.01.2015
    if IdTCPClient1.Connected then
      IdTCPClient1.Disconnect;
  end;
end;

end.
