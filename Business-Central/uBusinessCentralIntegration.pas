unit uBusinessCentralIntegration;

interface

{$DEFINE WINDOWS_SERVICE}

uses
  System.Classes,
  System.NetEncoding,
  System.SysUtils,
  System.StrUtils,
  REST.Client,
  System.Generics.Collections,
  REST.Authenticator.Basic,
  REST.Types,
  System.Json,
  MVCFramework,
  MVCFramework.Serializer.Defaults,
  MVCFramework.Serializer.Commons,
  MVCFramework.Serializer.JsonDataObjects,
  System.IOUtils;

type
  // General responsetype
  TBusinessCentral_Response = class
  end;

(*Errorresponse type*)
  TBusinessCentral_ErrorResponse = class(TBusinessCentral_Response)
  private
    FStatusCode: integer;
    FStatusText: string;
  public
    property StatusCode: integer read FStatusCode write FStatusCode;
    property StatusText: string read FStatusText write FStatusText;
  end;

  TBusinessCentral_Error_Response_Body = class
  private
    FCode: string;
    FMessage: string;
  public
    property code: string read FCode write FCode;
    [MVCNameAs('message')]
    property message_: string read FMessage write FMessage;
  end;

  TBusinessCentral_Error_Response = class(TBusinessCentral_Response)
  private
    FError: TBusinessCentral_Error_Response_Body;
  public
    property error: TBusinessCentral_Error_Response_Body read FError write FError;
    constructor Create;
    destructor Destroy; override;
  end;

// Class holds settings to communicate with Business Central
  TBusinessCentralSetup = class
  private
    FIP: string;
    FPort: string;
    FBaseUrl: string;
    FEndPoint: string;
    FUserName: string;
    FPassword: string;
    FCompanyID: string;
    FFilterValue: string;
    FOrderValue: string;
    FSelectValue: string;
    FFilterName: string;
    FOrderName: string;
    FSelectName: string;
    FCompaniesAPI: string;
    FMetadataAPI: string;
    FCustomAPIMetadata: string;
    FkmCashstatements: string;
    FkmItem: string;
    FkmVariantId: string;
    FkmItemSale: string;
    FkmItemMove: string;
    FkmItemStock: string;
    FkmItemAccess: string;
    FkmPurchaseHeader: string;
    FkmPurchaseInvoiceLines: string;
    FkmDocumentApproval: string;
    FkmVendor: string;
  public
    constructor Create(aIP, aPort, aEndPoint, aCompanyID, aUserName, aPassword: string);
    property IP: string read FIP write FIP;
    property Port: string read FPort write FPort;
    property BaseUrl: string read FBaseUrl;
    property EndPoint: string read FEndPoint write FEndPoint;
    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword;
    property CompanyID: string read FCompanyID write FCompanyID;
    property FilterValue: string read FFilterValue write FFilterValue;
    property OrderValue: string read FOrderValue write FOrderValue;
    property SelectValue: string read FSelectValue write FSelectValue;
    property FilterName: string read FFilterName;
    property OrderName: string read FOrderName;
    property SelectName: string read FSelectName;
    property CompaniesAPI: string read FCompaniesAPI;
    property MetadataAPI: string read FMetadataAPI;
    property CustomAPIMetadata: string read FCustomAPIMetadata;
    property kmCashstatements: string read FkmCashstatements;
    property kmItem: string read FkmItem;
    property kmVariantId: string read FkmVariantId;
    property kmItemSale: string read FkmItemSale;
    property kmItemMove: string read FkmItemMove;
    property kmItemStock: string read FkmItemStock;
    property kmItemAccess: string read FkmItemAccess;
    property kmPurchaseHeader: string read FkmPurchaseHeader;
    property kmPurchaseInvoiceLines: string read FkmPurchaseInvoiceLines;
    property kmDocumentApproval: string read FkmDocumentApproval;
    property kmVendor: string read FkmVendor write FkmVendor;
  end;

  TkmCashstatement = class(TBusinessCentral_Response)
  private
    Fodata_etag: string;
    FsystemId: string;
    FtransId: integer;
    FepId: integer;
    Fbutik: string;
    Ftype_: string;
    Fid: string;
    FbogfRingsDato: string;
    Fbilagsnummer: string;
    Ftext: string;
    FbelB: double;
    Fkasse: string;
    Fafdeling: string;
    FkasseOpgRelsestidspunkt: string;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
    {private declarations}
  public
    {public declarations}
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property odata_etag: string read Fodata_etag write Fodata_etag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property epId: integer read FepId write FepId;
    property butik: string read Fbutik write Fbutik;
    [MVCNameAs('type')]
    property type_: string read Ftype_ write Ftype_;
    property id: string read Fid write Fid;
    property bogfRingsDato: string read FbogfRingsDato write FbogfRingsDato;
    property bilagsnummer: string read Fbilagsnummer write Fbilagsnummer;
    property text: string read Ftext write Ftext;
    property belB: double read FbelB write FbelB;
    property kasse: string read Fkasse write Fkasse;
    property afdeling: string read Fafdeling write Fafdeling;
    property kasseOpgRelsestidspunkt: string read FkasseOpgRelsestidspunkt write FkasseOpgRelsestidspunkt;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

  TkmCashstatements = class(TBusinessCentral_Response)
  private
    {private declarations}
    Fodata_context: string;
    FValue: TObjectList<TkmCashstatement>;
  public
    {public declarations}
    [MVCNameAs('@odata.context')]
    property odata_context: string read Fodata_context write Fodata_context;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmCashstatement> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  // This class hold one item
  TkmItem = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtariffNo: string;
    FcountryRegionOfOriginCode: string;
    FnetWeight: double;
    FtransId: integer;
    FVareId: string;
    FBeskrivelse: string;
    FModel: string;
    FKostPris: double;
    FSalgspris: double;
    FLeverandRKode: string;
    FVaregruppe: string;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property tariffNo: string read FtariffNo write FtariffNo;
    property countryRegionOfOriginCode: string read FcountryRegionOfOriginCode write FcountryRegionOfOriginCode;
    property netWeight: double read FnetWeight write FnetWeight;
    property transId: integer read FtransId write FtransId;
    property vareId: string read FVareId write FVareId;
    property beskrivelse: string read FBeskrivelse write FBeskrivelse;
    property model: string read FModel write FModel;
    property kostPris: double read FKostPris write FKostPris;
    property salgspris: double read FSalgspris write FSalgspris;
    property leverandRKode: string read FLeverandRKode write FLeverandRKode;
    property varegruppe: string read FVaregruppe write FVaregruppe;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

// This calls holds items
  [MVCNameCase(ncLowerCase)]
  TkmItems = class(TBusinessCentral_Response)
  private
    {private declarations}
    FOdataContext: string;
    FValue: TObjectList<TkmItem>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
// [MVCNameAs('value')]
    property Value: TObjectList<TkmItem> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmVariantId = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FVareId: string;
    FVariantId: string;
    FFarve: string;
    FStRrelse: string;
    FLNgde: string;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property vareId: string read FVareId write FVareId;
    property variantId: string read FVariantId write FVariantId;
    property farve: string read FFarve write FFarve;
    property stRrelse: string read FStRrelse write FStRrelse;
    property lNgde: string read FLNgde write FLNgde;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

  TkmVariantIds = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmVariantId>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmVariantId> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

type
  TkmItemSale = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FepId: integer;
    FBonNummer: integer;
    FVareId: string;
    FVariantId: string;
    FbogfRingsDato: string;
    FAntal: double;
    FSalgspris: double;
    FButikId: string;
    FGaveKortId: string;
    FKostPris: double;
    FSalgstidspunkt: string;
    Fkasse: string;
    FMomsbelB: double;
    FLagerStatus: string;
    FFinansStatus: string;
    FtransDato: string;
    FtransTid: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property epId: integer read FepId write FepId;
    property bonNummer: integer read FBonNummer write FBonNummer;
    property vareId: string read FVareId write FVareId;
    property variantId: string read FVariantId write FVariantId;
    property bogfRingsDato: string read FbogfRingsDato write FbogfRingsDato;
    property antal: double read FAntal write FAntal;
    property salgspris: double read FSalgspris write FSalgspris;
    property gaveKortId: string read FGaveKortId write FGaveKortId;
    property kostPris: double read FKostPris write FKostPris;
    property salgstidspunkt: string read FSalgstidspunkt write FSalgstidspunkt;
    property kasse: string read Fkasse write Fkasse;
    property momsbelB: double read FMomsbelB write FMomsbelB;
    property butikId: string read FButikId write FButikId;
    property lagerStatus: string read FLagerStatus write FLagerStatus;
    property finansStatus: string read FFinansStatus write FFinansStatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

  TkmItemSales = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmItemSale>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmItemSale> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmItemMove = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FFlytningsId: string;
    FVareId: string;
    FVariantId: string;
    FepId: integer;
    FbogfRingsDato: string;
    FFraButik: string;
    FTilButik: string;
    FAntal: double;
    FKostPris: double;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property flytningsId: string read FFlytningsId write FFlytningsId;
    property vareId: string read FVareId write FVareId;
    property variantId: string read FVariantId write FVariantId;
    property epId: integer read FepId write FepId;
    property bogfRingsDato: string read FbogfRingsDato write FbogfRingsDato;
    property fraButik: string read FFraButik write FFraButik;
    property tilButik: string read FTilButik write FTilButik;
    property antal: double read FAntal write FAntal;
    property kostPris: double read FKostPris write FKostPris;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

  TkmItemMoves = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmItemMove>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmItemMove> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmItemStock = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FButikId: string;
    FVareId: string;
    FVariantId: string;
    FOptaltAntal: double;
    FbogfRingsDato: string;
    FKostPris: double;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
    FOptLlingsType: integer;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property butikId: string read FButikId write FButikId;
    property vareId: string read FVareId write FVareId;
    property variantId: string read FVariantId write FVariantId;
    property optaltAntal: double read FOptaltAntal write FOptaltAntal;
    property bogfRingsDato: string read FbogfRingsDato write FbogfRingsDato;
    property kostPris: double read FKostPris write FKostPris;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    property optLlingsType: integer read FOptLlingsType write FOptLlingsType;
    function GeteTagToUSeInHeader: string;
  end;

  TkmItemStocks = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmItemStock>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmItemStock> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmItemAccess = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FButikId: string;
    FLeverandRKode: string;
    Flagertilgangsnummer: string;
    FbogfRingsDato: string;
    FbelB: double;
    Fstatus: string;
    FtilbagefRt: boolean;
    FtransDato: string;
    FtransTid: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property butikId: string read FButikId write FButikId;
    property leverandRKode: string read FLeverandRKode write FLeverandRKode;
    property lagertilgangsnummer: string read Flagertilgangsnummer write Flagertilgangsnummer;
    property bogfRingsDato: string read FbogfRingsDato write FbogfRingsDato;
    property belB: double read FbelB write FbelB;
    property status: string read Fstatus write Fstatus;
    property tilbagefRt: boolean read FtilbagefRt write FtilbagefRt;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

  TkmItemAccesss = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmItemAccess>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmItemAccess> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmPurchaseHeader = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FButikId: string;
    FFakturaId: string;
    FLeverandRId: string;
    FEksterntFakturaId: string;
    FbogfRingsDato: string;
    Flagertilgangsnummer: string;
    FInfo: string;
    FKreditNota: boolean;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
    FDocumentNo: string;
    FDocumentType: integer;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property butikId: string read FButikId write FButikId;
    property fakturaId: string read FFakturaId write FFakturaId;
    property leverandRId: string read FLeverandRId write FLeverandRId;
    property eksterntFakturaId: string read FEksterntFakturaId write FEksterntFakturaId;
    property bogfRingsDato: string read FbogfRingsDato write FbogfRingsDato;
    property lagertilgangsnummer: string read Flagertilgangsnummer write Flagertilgangsnummer;
    property info: string read FInfo write FInfo;
    property kreditNota: boolean read FKreditNota write FKreditNota;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    property documentNo: string read FDocumentNo write FDocumentNo;
    property documentType: integer read FDocumentType write FDocumentType;
    function GeteTagToUSeInHeader: string;
  end;

  TkmPurchaseHeaders = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmPurchaseHeader>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmPurchaseHeader> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmPurchaseInvoiceLine = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FFakturaId: string;
    FLinieNummer: integer;
    FVareId: string;
    FVariantId: string;
    FAntal: double;
    FKBsPris: double;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property fakturaId: string read FFakturaId write FFakturaId;
    property linieNummer: integer read FLinieNummer write FLinieNummer;
    property vareId: string read FVareId write FVareId;
    property variantId: string read FVariantId write FVariantId;
    property antal: double read FAntal write FAntal;
    property kBsPris: double read FKBsPris write FKBsPris;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

  TkmPurchaseInvoiceLines = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmPurchaseInvoiceLine>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmPurchaseInvoiceLine> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmDocumentApproval = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FEntryNo: integer;
    FDocumentTableId: integer;
    FDocumentType: string;
    FDocumentNo: string;
    FShopCode: string;
    FDepartmentCode: string;
    FVendorOrderNo: string;
    FVendorShipmentNo: string;
    FVendorCrMemoNo: string;
    FVendorInvoiceNo: string;
    FAmount: double;
    FAmountInclVAT: double;
    FAmountLCY: double;
    FApprovalStatus: string;
    FReturnMessage: string;
    FLockedByEasyPos: boolean;
    FVendorNo: string;
    FVendorName: string;
    FDcDocumentNo: string;
    FImageFileName: string;
    Fstatus: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property entryNo: integer read FEntryNo write FEntryNo;
    property documentTableId: integer read FDocumentTableId write FDocumentTableId;
    property documentType: string read FDocumentType write FDocumentType;
    property documentNo: string read FDocumentNo write FDocumentNo;
    property shopCode: string read FShopCode write FShopCode;
    property departmentCode: string read FDepartmentCode write FDepartmentCode;
    property vendorOrderNo: string read FVendorOrderNo write FVendorOrderNo;
    property vendorShipmentNo: string read FVendorShipmentNo write FVendorShipmentNo;
    property vendorCrMemoNo: string read FVendorCrMemoNo write FVendorCrMemoNo;
    property vendorInvoiceNo: string read FVendorInvoiceNo write FVendorInvoiceNo;
    property amount: double read FAmount write FAmount;
    property amountInclVAT: double read FAmountInclVAT write FAmountInclVAT;
    property amountLCY: double read FAmountLCY write FAmountLCY;
    property approvalStatus: string read FApprovalStatus write FApprovalStatus;
    property returnMessage: string read FReturnMessage write FReturnMessage;
    property lockedByEasyPos: boolean read FLockedByEasyPos write FLockedByEasyPos;
    property vendorNo: string read FVendorNo write FVendorNo;
    property vendorName: string read FVendorName write FVendorName;
    property dcDocumentNo: string read FDcDocumentNo write FDcDocumentNo;
    property imageFileName: string read FImageFileName write FImageFileName;
    [MVCDoNotSerialize]
    property status: string read Fstatus write Fstatus;
    function GeteTagToUSeInHeader: string;
    function GetdocumentType: integer;
    function GetapprovalStatusAsInteger: integer;
    function GetapprovalStatusAsString(aApprovalStatus: integer): string;
  end;

  TkmDocumentApprovals = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmDocumentApproval>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmDocumentApproval> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

  TkmVendor = class(TBusinessCentral_Response)
  private
    FOdataEtag: string;
    FsystemId: string;
    FtransId: integer;
    FLeverandRId: string;
    Fnavn: string;
    FvalutaKode: string;
    FLeverandRKode: string;
    Fstatus: string;
    FtransDato: string;
    FtransTid: string;
  public
    [MVCNameAs('@odata.etag')]
    [MVCDoNotSerialize]
    property OdataEtag: string read FOdataEtag write FOdataEtag;
    [MVCDoNotSerialize]
    property systemId: string read FsystemId write FsystemId;
    property transId: integer read FtransId write FtransId;
    property leverandRId: string read FLeverandRId write FLeverandRId;
    property navn: string read Fnavn write Fnavn;
    property valutaKode: string read FvalutaKode write FvalutaKode;
    property leverandRKode: string read FLeverandRKode write FLeverandRKode;
    property status: string read Fstatus write Fstatus;
    property transDato: string read FtransDato write FtransDato;
    property transTid: string read FtransTid write FtransTid;
    function GeteTagToUSeInHeader: string;
  end;

  TkmVendors = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TkmVendor>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TkmVendor> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
  end;

// Class that handle all communication with Business Central
  // This containts Client, Request, Response og Basic Authentication
  TBusinessCentralHTTP = class
  private
    FClient: TRestClient;
    FResponse: TRestResponse;
    FRequest: TRestRequest;
    FBasicAuthenticator: THTTPBasicAuthenticator;
  public
    property Client: TRestClient read FClient write FClient;
    property Response: TRestResponse read FResponse write FResponse;
    property Request: TRestRequest read FRequest write FRequest;
    property BasicAuthenticator: THTTPBasicAuthenticator read FBasicAuthenticator write FBasicAuthenticator;
    constructor Create(aBusinessCentralSetup: TBusinessCentralSetup; aMethod: TRESTRequestMethod; aBasicCall: boolean = FALSE);
    destructor Destroy; override;
  end;

  // Denne klasse indeholder procedure, der kan sætte RESTClient, RESTRequest, RESTResponse og BasicAuthenticatiojn op
  // Lilgeledes indeholder den selve funktionen, der skal udføres.
  TBusinessCentral = class
  private
    {private declarations}
    FLogFileFolder: string;
    FTotalLogFile: string;
    FErrorLogFile: string;
    procedure WriteBCLogFile(aText: string);
    procedure WriteBCErrorFile(aText: string);

    procedure SetupCompaniesRequest(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupMetadataRequest(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupCustomAPIMetadataRequest(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);

    procedure SetupGETkmCashstatements(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPOSTkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETEkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPUTkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmItems(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmItem(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmItem(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETEkmItem(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETEkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);

    procedure SetupGETkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupPUTkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
    procedure SetupPOSTkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
    procedure SetupDELETETkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
  public
    {public declarations}
// property LogFileFolder: string read FLogFileFolder write FLogFileFolder;
// property TotalLogFile: string read FTotalLogFile write FTotalLogFile;
// property ErrorLogFile: string read FErrorLogFile write FErrorLogFile;

    function GetCompanies(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function GetMetadata(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: string): boolean;
    function GetCustomAPIMetadata(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: string): boolean;

    function GetkmCashstatements(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; akmCashstatement: TkmCashstatement; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmItems(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmItem(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmItem(aBusinessCentralSetup: TBusinessCentralSetup; akmItem: TkmItem; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmItem(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmVariantIds(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; akmVariantId: TkmVariantId; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmItemSale(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmItemSale(aBusinessCentralSetup: TBusinessCentralSetup; akmItemSale: TkmItemSale; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmItemSale(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmItemMove(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmItemMove(aBusinessCentralSetup: TBusinessCentralSetup; akmItemMove: TkmItemMove; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmItemMove(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmItemStock(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmItemStock(aBusinessCentralSetup: TBusinessCentralSetup; akmItemStock: TkmItemStock; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmItemStock(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmItemAccess(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmItemAccess(aBusinessCentralSetup: TBusinessCentralSetup; akmItemAccess: TkmItemAccess; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmItemAccess(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
    function PutkmPurchaseHeader(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmPurchaseHeader(aBusinessCentralSetup: TBusinessCentralSetup; akmPurchaseHeader: TkmPurchaseHeader; out aResponse: TBusinessCentral_Response; aOnlyTest: boolean; aLogCall: boolean; out aJSONBody: String): boolean;
    function DeletekmPurchaseHeader(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;

    function GetkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
    function PutkmPurchaseInvoiceLine(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmPurchaseInvoiceLine(aBusinessCentralSetup: TBusinessCentralSetup; akmPurchaseInvoiceLine: TkmPurchaseInvoiceLine; out aResponse: TBusinessCentral_Response; aOnlyTest: boolean; aLogCall: boolean; aJSONBody: string): boolean;
    function DeletekmPurchaseInvoiceLine(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;

    function GetkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
    function PutkmDocumentApproval(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
    function PostkmDocumentApproval(aBusinessCentralSetup: TBusinessCentralSetup; akmDocumentApproval: TkmDocumentApproval; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmDocumentApproval(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;

    function GetkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
    function PutkmVendor(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
    function PostkmVendor(aBusinessCentralSetup: TBusinessCentralSetup; akmVendor: TkmVendor; out aResponse: TBusinessCentral_Response): boolean;
    function DeletekmVendor(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
    constructor Create(aLogFileFolder: String);
    destructor Destroy; override;
  end;

  // One company
  [MVCNameCase(ncLowerCase)]
  TBCCompany = class
  private
    FBusinessProfileId: string;
    FDisplayName: string;
    Fid: string;
    FName: string;
    FSystemCreatedAt: TDateTime;
    FSystemCreatedBy: string;
    FSystemModifiedAt: TDateTime;
    FSystemModifiedBy: string;
    FSystemVersion: string;
  public
    property BusinessProfileId: string read FBusinessProfileId write FBusinessProfileId;
    property DisplayName: string read FDisplayName write FDisplayName;
    property id: string read Fid write Fid;
    property Name: string read FName write FName;
    property SystemCreatedAt: TDateTime read FSystemCreatedAt write FSystemCreatedAt;
    property SystemCreatedBy: string read FSystemCreatedBy write FSystemCreatedBy;
    property SystemModifiedAt: TDateTime read FSystemModifiedAt write FSystemModifiedAt;
    property SystemModifiedBy: string read FSystemModifiedBy write FSystemModifiedBy;
    property SystemVersion: string read FSystemVersion write FSystemVersion;
  end;

  // List of companies
  TBCCompanies = class(TBusinessCentral_Response)
  private
    FOdataContext: string;
    FValue: TObjectList<TBCCompany>;
  public
    [MVCNameAs('@odata.context')]
    property OdataContext: string read FOdataContext write FOdataContext;
    [MVCNameAs('value')]
    property Value: TObjectList<TBCCompany> read FValue write FValue;
    constructor Create;
    destructor Destroy; override;
{$IFNDEF WINDOWS_SERVICE}
    function SelectCompanyName: string;
{$ENDIF}
  end;

implementation

{$IFNDEF WINDOWS_SERVICE}
uses
  USelectCompany;
{$ENDIF}

constructor TBusinessCentralHTTP.Create(aBusinessCentralSetup: TBusinessCentralSetup; aMethod: TRESTRequestMethod; aBasicCall: boolean);
var
  lStr: string;
begin
  // This will create the need components to coomunicate with BC.
  // BasicCall is without any company indication. Used to get companies.
  // If CompanyID is not set, a list of customer APIs can be returned.

  // Create Client
  if aBasicCall then
    FClient := TRestClient.Create(aBusinessCentralSetup.BaseUrl)
  else
  begin
    if aBusinessCentralSetup.CompanyID <> '' then
      FClient := TRestClient.Create(aBusinessCentralSetup.BaseUrl + aBusinessCentralSetup.EndPoint + Format('/companies(%s)', [aBusinessCentralSetup.CompanyID]))
    else
      FClient := TRestClient.Create(aBusinessCentralSetup.BaseUrl + aBusinessCentralSetup.EndPoint);
  end;
  lStr := FClient.BaseUrl;
  // Create request
  FRequest := TRestRequest.Create(FClient);
  // Create Response
  FResponse := TRestResponse.Create(FClient);
  // Create Basic Authentication
  FBasicAuthenticator := THTTPBasicAuthenticator.Create(FClient);
  FBasicAuthenticator.UserName := aBusinessCentralSetup.UserName;
  FBasicAuthenticator.Password := aBusinessCentralSetup.Password;

  // Set client to use Basic Authentication
  FClient.Authenticator := FBasicAuthenticator;
  // Set method to use
  FRequest.Method := aMethod;

  // I have tried to remove above FBasisAuthentication. Then I am unauthorized
  // Then I added the below code. All worked again (except PUT/PATCH)
// FRequest.AddAuthParameter('Authorization', 'Basic bWljcm9jb21wb3M6bGI2ZmozZ21Wa0Z1a1hlOUtNbllZdGk0SWR5VUJrbzRBL2p4aWtOSTZ0QT0=', TRESTRequestParameterKind.pkHTTPHEADER,[TRESTRequestParameterOption.poDoNotEncode]);

  // Set general response type
  FResponse.ContentType := 'application/json';
  // Set response to request
  FRequest.Response := FResponse;
end;

destructor TBusinessCentralHTTP.Destroy;
begin
  // Free client (And thereby request, response and basic authentitation)
  FClient.Free;
  inherited;
end;

{TBusinessCentral}

procedure TBusinessCentral.SetupCompaniesRequest(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET, TRUE);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.CompaniesAPI]);
end;

procedure TBusinessCentral.SetupMetadataRequest(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET, TRUE);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.MetadataAPI]);
end;

procedure TBusinessCentral.SetupCustomAPIMetadataRequest(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.CustomAPIMetadata]);
end;

procedure TBusinessCentral.SetupDELETEkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmCashstatements, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETEkmItem(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItem, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETEkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmVariantId, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmDocumentApproval, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemAccess, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemMove, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemSale, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemStock, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmPurchaseHeader, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmPurchaseInvoiceLines, aSystemID]);
end;

procedure TBusinessCentral.SetupDELETETkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmDELETE);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmVendor, aSystemID]);
end;

procedure TBusinessCentral.SetupPOSTkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmCashstatements]);
end;

procedure TBusinessCentral.SetupPOSTkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmDocumentApproval]);
end;

procedure TBusinessCentral.SetupPOSTkmItem(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItem]);
end;

procedure TBusinessCentral.SetupPOSTkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemAccess]);
end;

procedure TBusinessCentral.SetupPOSTkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemMove]);
end;

procedure TBusinessCentral.SetupPOSTkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemSale]);
end;

procedure TBusinessCentral.SetupPOSTkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemStock]);
end;

procedure TBusinessCentral.SetupPOSTkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmPurchaseHeader]);
end;

procedure TBusinessCentral.SetupPOSTkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmPurchaseInvoiceLines]);
end;

procedure TBusinessCentral.SetupPOSTkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmVariantId]);
end;

procedure TBusinessCentral.SetupPOSTkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPOST);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmVendor]);
end;

procedure TBusinessCentral.SetupPUTkmItem(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItem, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemAccess, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemMove, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemSale, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmItemStock, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmPurchaseHeader, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmPurchaseInvoiceLines, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmVariantId, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmVendor, aSystemID]);
end;

procedure TBusinessCentral.WriteBCErrorFile(aText: string);
begin
  try
    TFile.AppendAllText(FErrorLogFile, FormatDateTime('dd-mm-yy hh:mm:ss', NOW) + ': ' + aText + #13#10);
  except
    try
      TFile.AppendAllText(FErrorLogFile, FormatDateTime('dd-mm-yy hh:mm:ss', NOW) + ': ' + 'Can not write to logfile' + #13#10);
    except

    end;
  end;
end;

procedure TBusinessCentral.WriteBCLogFile(aText: string);
begin
  try
    TFile.AppendAllText(FTotalLogFile, FormatDateTime('dd-mm-yy hh:mm:ss', NOW) + ': ' + aText + #13#10);
  except
    try
      TFile.AppendAllText(FTotalLogFile, FormatDateTime('dd-mm-yy hh:mm:ss', NOW) + ': ' + 'Can not write to logfile' + #13#10);
    except

    end;
  end;
end;

procedure TBusinessCentral.SetupPUTkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmCashstatements, aSystemID]);
end;

procedure TBusinessCentral.SetupPUTkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP; aSystemID: string);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmPUT);
  aBusinessCentralHTTP.Request.Resource := Format('%s(%s)', [aBusinessCentralSetup.kmDocumentApproval, aSystemID]);
end;

procedure TBusinessCentral.SetupGETkmCashstatements(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmCashstatements]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmDocumentApproval]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemAccess]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemMove]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmItems(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItem]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemSale]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmItemStock]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmPurchaseHeader]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmPurchaseInvoiceLines]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmVariantId]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

procedure TBusinessCentral.SetupGETkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; var aBusinessCentralHTTP: TBusinessCentralHTTP);
begin
  // Create client and set basic URL and afterwards set resource
  aBusinessCentralHTTP := TBusinessCentralHTTP.Create(aBusinessCentralSetup, rmGET);
  aBusinessCentralHTTP.Request.Resource := Format('%s', [aBusinessCentralSetup.kmVendor]);
  // add filer (Limit)
  if (aBusinessCentralSetup.FilterValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.FilterName, aBusinessCentralSetup.FilterValue);
  // Add order by
  if (aBusinessCentralSetup.OrderValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.OrderName, aBusinessCentralSetup.OrderValue);
  // Add Select FIelds
  if (aBusinessCentralSetup.SelectValue <> '') then
    aBusinessCentralHTTP.Request.AddParameter(aBusinessCentralSetup.SelectName, aBusinessCentralSetup.SelectValue);
end;

function TBusinessCentral.PutkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmCashstatement(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
// lBusinessCentralHTTP.Request.Params.AddHeader('If-Match',aeTag);
// lBusinessCentralHTTP.Request.AddParameter('If-Match',aeTag, pkHTTPHEADER, [poDoNotEncode});

      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmCashstatements.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmDocumentApproval(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  if aLogCall then
  begin
    WriteBCLogFile(' ');
    WriteBCLogFile('PutkmDocumentApproval');
  end;
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmDocumentApprovals(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      if aLogCall then
      begin
        lStr := Format('%s with value: %s',[Name, Value]);
        WriteBCLogFile(lStr);
        WriteBCLogFile(aBody);
      end;
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);

      if aLogCall then
      begin
        WriteBCLogFile('Body (JSON): ');
        WriteBCLogFile(aBody);
      end;

      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmDocumentApprovals.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile(' ');
          WriteBCErrorFile('PutkmDocumentApproval');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmItem(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmItem(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmItems.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmItemAccess(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmItemAccesss(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmItemAccesss.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmItemMove(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmItemMoves(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmItemMoves.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmItemSale(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmItemSales(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmItemSales.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmItemStock(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmItemStocks(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmItemStocks.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmPurchaseHeader(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmPurchaseHeaders(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmPurchaseHeaders.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmPurchaseInvoiceLine(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmPurchaseInvoiceLines(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmPurchaseInvoiceLines.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmVariantId(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmVariantIds.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PutkmVendor(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag, aBody: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup alt til kommunikationen
  SetupPUTkmVendors(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Add If_match til headder.
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;

      // Add body
      lBusinessCentralHTTP.Request.Body.Add(aBody, ctAPPLICATION_JSON);
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200: // Updated. Contains new record
          begin
            aResponse := TkmVendors.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

constructor TBusinessCentral.Create(aLogFileFolder: String);
begin
  FLogFileFolder := aLogFileFolder + 'BC_Log\';
  ForceDirectories(FLogFileFolder);
  FTotalLogFile := FLogFileFolder + Format('BusinessCentralCommunication_%s.txt', [FormatDateTime('yyyy-mm-dd', NOW)]);
  FErrorLogFile := FLogFileFolder + Format('BusinessCentral_Errors_%s.txt', [FormatDateTime('yyyy-mm-dd', NOW)]);
end;

function TBusinessCentral.DeletekmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETEkmCashstatement(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmCashstatement.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmDocumentApproval(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETETkmDocumentApprovals(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmItem(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETEkmItem(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmItemAccess(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETETkmItemAccesss(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmItemMove(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETETkmItemMoves(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmItemSale(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETETkmItemSales(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmItemStock(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETETkmItemStocks(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmPurchaseHeader(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  if aLogCall then
  begin
    WriteBCLogFile(' ');
    WriteBCLogFile('DeletekmPurchaseHeader');
  end;
  result := FALSE;
  // Setup
  SetupDELETETkmPurchaseHeaders(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  if aLogCall then
  begin
    WriteBCLogFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
    WriteBCLogFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
    WriteBCLogFile('eTag: ' + aeTag);
    WriteBCLogFile('SystemID: ' + aSystemID);
  end;
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            if (aLogCall) then
            begin
              WriteBCLogFile('All good. Record deleted');
              WriteBCLogFile('Response: ' + lBusinessCentralHTTP.Response.Content);
            end;
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile(' ');
          WriteBCErrorFile('DeletekmPurchaseHeader');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmPurchaseInvoiceLine(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  if aLogCall then
  begin
    WriteBCLogFile(' ');
    WriteBCLogFile('DeletekmPurchaseInvoiceLine');
  end;
  result := FALSE;
  // Setup
  SetupDELETETkmPurchaseInvoiceLines(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  if aLogCall then
  begin
    WriteBCLogFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
    WriteBCLogFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
    WriteBCLogFile('eTag: ' + aeTag);
    WriteBCLogFile('SystemID: ' + aSystemID);
  end;
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            WriteBCLogFile('All good. Record deleted');
            WriteBCLogFile('Response: ' + lBusinessCentralHTTP.Response.Content);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile(' ');
          WriteBCErrorFile('DeletekmPurchaseInvoiceLine');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETEkmVariantId(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.DeletekmVendor(aBusinessCentralSetup: TBusinessCentralSetup; aSystemID, aeTag: string; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
begin
  // This will delete a record. It will be matched by:
  // systemID: This is set in the URL last in ()
  // eTag: Will be set in header as If_Match. \ will be removed
  result := FALSE;
  // Setup
  SetupDELETETkmVendors(aBusinessCentralSetup, lBusinessCentralHTTP, aSystemID);
  try
    try
      // Set If_Match
      with lBusinessCentralHTTP.Request.Params.AddItem do
      begin
        Kind := TRESTRequestParameterKind.pkHTTPHEADER;
        Name := 'If-Match';
        Value := aeTag;
        Options := Options + [TRESTRequestParameterOption.poDoNotEncode];
      end;
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        204: // Delete - Contains no body
          begin
            aResponse := TkmItem.Create;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

destructor TBusinessCentral.Destroy;
begin

  inherited;
end;

function TBusinessCentral.GetCompanies(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  result := FALSE;
  SetupCompaniesRequest(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TBCCompanies.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetMetadata(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: string): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  result := FALSE;
  SetupMetadataRequest(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := lBusinessCentralHTTP.Response.Content;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := Format('{ "StatusCode" : %s, "StatusText" : "%s" }', [lBusinessCentralHTTP.Response.StatusCode, lBusinessCentralHTTP.Response.StatusText]);
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmCashstatement(aBusinessCentralSetup: TBusinessCentralSetup; akmCashstatement: TkmCashstatement; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmCashstatement(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmCashstatement);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmCashstatement.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmDocumentApproval(aBusinessCentralSetup: TBusinessCentralSetup; akmDocumentApproval: TkmDocumentApproval; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmDocumentApprovals(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmDocumentApproval);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmDocumentApproval.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmItem(aBusinessCentralSetup: TBusinessCentralSetup; akmItem: TkmItem; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmItem(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmItem);
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);

      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmItem.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmItemAccess(aBusinessCentralSetup: TBusinessCentralSetup; akmItemAccess: TkmItemAccess; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmItemAccesss(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmItemAccess);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmItemAccess.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmItemMove(aBusinessCentralSetup: TBusinessCentralSetup; akmItemMove: TkmItemMove; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmItemMoves(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmItemMove);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmItemMove.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmItemSale(aBusinessCentralSetup: TBusinessCentralSetup; akmItemSale: TkmItemSale; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmItemSales(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmItemSale);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmItemSale.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmItemStock(aBusinessCentralSetup: TBusinessCentralSetup; akmItemStock: TkmItemStock; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmItemStocks(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmItemStock);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmItemStock.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmPurchaseHeader(aBusinessCentralSetup: TBusinessCentralSetup; akmPurchaseHeader: TkmPurchaseHeader; out aResponse: TBusinessCentral_Response; aOnlyTest: boolean; aLogCall: boolean; out aJSONBody: String): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  if aLogCall then
  begin
    WriteBCLogFile(' ');
    if aOnlyTest then
      WriteBCLogFile('PostkmPurchaseHeader - TEST TEST TEST')
    else
      WriteBCLogFile('PostkmPurchaseHeader');
  end;
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmPurchaseHeaders(aBusinessCentralSetup, lBusinessCentralHTTP);
  if aLogCall then
  begin
    WriteBCLogFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
    WriteBCLogFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
  end;
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmPurchaseHeader);
      aJSONBody := lStr;
      if aLogCall then
      begin
        WriteBCLogFile('Body (JSON): ');
        WriteBCLogFile(lStr);
      end;
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      if aOnlyTest then
      begin
        if (aLogCall) then
        begin
          WriteBCLogFile('No actual call made.');
          result := TRUE;
        end;
      end
      else
      begin
        lBusinessCentralHTTP.Request.Execute;
        case lBusinessCentralHTTP.Response.StatusCode of
          201: // Created
            begin
              aResponse := TkmPurchaseHeader.Create;
              GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
              if (aLogCall) then
              begin
                WriteBCLogFile('All good. Record created');
                WriteBCLogFile('Response: ' + lBusinessCentralHTTP.Response.Content);
              end;
              result := TRUE;
            end;
        else
          begin
            result := FALSE;
            WriteBCErrorFile(' ');
            WriteBCErrorFile('PostkmPurchaseHeader');
            WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
            WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
            WriteBCErrorFile('Body (JSON): ');
            WriteBCErrorFile(lStr);
            WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
            WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
            aResponse := TBusinessCentral_ErrorResponse.Create;
            (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
            (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
          end;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmPurchaseInvoiceLine(aBusinessCentralSetup: TBusinessCentralSetup; akmPurchaseInvoiceLine: TkmPurchaseInvoiceLine; out aResponse: TBusinessCentral_Response; aOnlyTest: boolean; aLogCall: boolean; aJSONBody: string): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  WriteBCLogFile(' ');
  if aLogCall then
  begin
    if aOnlyTest then
      WriteBCLogFile('PostkmPurchaseInvoiceLine - TEST TEST TEST')
    else
      WriteBCLogFile('PostkmPurchaseInvoiceLine');
  end;
  result := FALSE;
  // Setup
  SetupPOSTkmPurchaseInvoiceLines(aBusinessCentralSetup, lBusinessCentralHTTP);
  if aLogCall then
  begin
    WriteBCLogFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
    WriteBCLogFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
  end;
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmPurchaseInvoiceLine);
      aJSONBody := lStr;
      if aLogCall then
      begin
        WriteBCLogFile('Body (JSON): ');
        WriteBCLogFile(lStr);
      end;
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      if aOnlyTest then
      begin
        if aLogCall then
        begin
          WriteBCLogFile('No actual call made.');
          result := TRUE;
        end;
      end
      else
      begin
        lBusinessCentralHTTP.Request.Execute;
        case lBusinessCentralHTTP.Response.StatusCode of
          201: // Created
            begin
              aResponse := TkmPurchaseInvoiceLine.Create;
              GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
              result := TRUE;
            end;
        else
          begin
            result := FALSE;
            WriteBCErrorFile(' ');
            WriteBCErrorFile('PostkmPurchaseInvoiceLine');
            WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
            WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
            WriteBCErrorFile('Body (JSON): ');
            WriteBCErrorFile(lStr);
            WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
            WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
            aResponse := TBusinessCentral_ErrorResponse.Create;
            (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
            (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
          end;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmVariantId(aBusinessCentralSetup: TBusinessCentralSetup; akmVariantId: TkmVariantId; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmVariantId(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmVariantId);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmVariantId.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.PostkmVendor(aBusinessCentralSetup: TBusinessCentralSetup; akmVendor: TkmVendor; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
  lBusinessCentral_Error_Response: TBusinessCentral_Error_Response;
  lStr: string;
begin
  // This will insert a new record.
  result := FALSE;
  // Setup
  SetupPOSTkmVendors(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Serialize object
      lStr := GetDefaultSerializer.SerializeObject(akmVendor);
      // Set as body
      lBusinessCentralHTTP.Request.Body.Add(lStr, ctAPPLICATION_JSON);
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        201: // Created
          begin
            aResponse := TkmVendor.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile('PostkmCashstatement');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Body (JSON): ');
          WriteBCErrorFile(lStr);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.Content;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetCustomAPIMetadata(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: string): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  result := FALSE;
  SetupCustomAPIMetadataRequest(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := lBusinessCentralHTTP.Response.Content;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := Format('{ "StatusCode" : %s, "StatusText" : "%s" }', [lBusinessCentralHTTP.Response.StatusCode, lBusinessCentralHTTP.Response.StatusText]);
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmCashstatements(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmCashstatements(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmCashstatements.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmDocumentApprovals(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  if aLogCall then
  begin
    WriteBCLogFile(' ');
    WriteBCLogFile('GetkmDocumentApprovals');
  end;
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmDocumentApprovals(aBusinessCentralSetup, lBusinessCentralHTTP);
  if aLogCall then
  begin
    WriteBCLogFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
    WriteBCLogFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
    WriteBCLogFile('Filter: ' + aBusinessCentralSetup.FilterValue);
  end;
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmDocumentApprovals.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile(' ');
          WriteBCErrorFile('GetkmDocumentApprovals');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmItemAccesss(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmItemAccesss(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmItemAccesss.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmItemMoves(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmItemMoves(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmItemMoves.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmItems(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmItems(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmItems.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmItemSales(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmItemSales(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmItemSales.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmItemStocks(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmItemStocks(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmItemStocks.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmPurchaseHeaders(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  if aLogCall then
  begin
    WriteBCLogFile(' ');
    WriteBCLogFile('GetkmPurchaseHeaders');
  end;
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmPurchaseHeaders(aBusinessCentralSetup, lBusinessCentralHTTP);
  if aLogCall then
  begin
    WriteBCLogFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
    WriteBCLogFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
  end;
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmPurchaseHeaders.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            if (aLogCall) then
            begin
              WriteBCLogFile('All good. Record fetched');
              WriteBCLogFile('Response: ' + lBusinessCentralHTTP.Response.Content);
            end;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile(' ');
          WriteBCErrorFile('GetkmPurchaseHeaders');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmPurchaseInvoiceLines(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response; aLogCall: boolean): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  if aLogCall then
  begin
    WriteBCLogFile(' ');
    WriteBCLogFile('GetkmPurchaseInvoiceLines');
  end;
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmPurchaseInvoiceLines(aBusinessCentralSetup, lBusinessCentralHTTP);
  if aLogCall then
  begin
    WriteBCLogFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
    WriteBCLogFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
  end;
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmPurchaseInvoiceLines.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            if (aLogCall) then
            begin
              WriteBCLogFile('All good. Record fetched');
              WriteBCLogFile('Response: ' + lBusinessCentralHTTP.Response.Content);
            end;
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          WriteBCErrorFile(' ');
          WriteBCErrorFile('GetkmPurchaseInvoiceLines');
          WriteBCErrorFile('BaseURL: ' + lBusinessCentralHTTP.FClient.BaseUrl);
          WriteBCErrorFile('Endpoint: ' + lBusinessCentralHTTP.FRequest.Resource);
          WriteBCErrorFile('Statuscode: ' + lBusinessCentralHTTP.Response.StatusCode.ToString);
          WriteBCErrorFile('Content: ' + lBusinessCentralHTTP.Response.Content);
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmVariantIds(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmVariantId(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmVariantIds.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

function TBusinessCentral.GetkmVendors(aBusinessCentralSetup: TBusinessCentralSetup; out aResponse: TBusinessCentral_Response): boolean;
var
  lBusinessCentralHTTP: TBusinessCentralHTTP;
begin
  // This will fetch records
  result := FALSE;
  // System
  SetupGETkmVendors(aBusinessCentralSetup, lBusinessCentralHTTP);
  try
    try
      // Execute
      lBusinessCentralHTTP.Request.Execute;
      case lBusinessCentralHTTP.Response.StatusCode of
        200:
          begin
            aResponse := TkmVendors.Create;
            GetDefaultSerializer.DeserializeObject(lBusinessCentralHTTP.Response.Content, aResponse);
            result := TRUE;
          end;
      else
        begin
          result := FALSE;
          aResponse := TBusinessCentral_ErrorResponse.Create;
          (aResponse as TBusinessCentral_ErrorResponse).StatusCode := lBusinessCentralHTTP.Response.StatusCode;
          (aResponse as TBusinessCentral_ErrorResponse).StatusText := lBusinessCentralHTTP.Response.StatusText;
        end;
      end;
    except
      on E: Exception do
      begin
        result := FALSE;
        aResponse := TBusinessCentral_ErrorResponse.Create;
        GetDefaultSerializer.DeserializeObject(Format('{ "StatusCode" : -99, "StatusText" : "%s" }', [E.Message]), aResponse);
      end;
    end;
  finally
    lBusinessCentralHTTP.Free;
  end;
end;

{TBCCompanies}

constructor TBCCompanies.Create;
begin
  FValue := TObjectList<TBCCompany>.Create;
end;

destructor TBCCompanies.Destroy;
begin
  FValue.Free;
  inherited;
end;

{$IFNDEF WINDOWS_SERVICE}
function TBCCompanies.SelectCompanyName: string;
begin
  try
    try
      frmSelectCompany := TfrmSelectCompany.Create(nil);
      frmSelectCompany.SaetCompanyGrid(self);
      frmSelectCompany.ShowModal;
      result := frmSelectCompany.SelectedCompanyId;
    finally
      FreeAndNil(frmSelectCompany);
    end;
  except
    ;
    result := '';
  end;
end;
{$ENDIF}

{TkmCashstatements}

constructor TkmCashstatements.Create;
begin
  FValue := TObjectList<TkmCashstatement>.Create;
end;

destructor TkmCashstatements.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TBusinessCentralSetup}

constructor TBusinessCentralSetup.Create(aIP, aPort, aEndPoint, aCompanyID, aUserName, aPassword: string);
var
  pos1: Integer;
  pos2: Integer;
  substr: string;
  BCStr: string;
begin
  // Set basic values.
  FIP := aIP;
  FPort := aPort;
  FUserName := aUserName;
  FPassword := aPassword;
  FBaseUrl := Format('http://%s:%s', [aIP, aPort]);
  FEndPoint := aEndPoint;
  FCompanyID := aCompanyID;
  FFilterValue := '';
  FOrderValue := '';
  FSelectValue := '';
  FFilterName := '$filter';
  FOrderName := '$orderby';

  BCStr := FEndPoint;
  pos1 := Pos('/', BCStr);
  pos2 := PosEx('/', BCStr, pos1 + 1); // find the second occurrence of '/'
  if pos2 > 0 then
    substr := Copy(BCStr, 2, pos2-2) // extract the substring
  else
    substr := 'BCDRIFTPOS';

  FCompaniesAPI := Format('/%s/api/v2.0/companies',[SubStr]);
  FMetadataAPI := Format('/%s/api/v2.0/$metadata',[SubStr]);
  FCustomAPIMetadata := '/$metadata';
  FkmCashstatements := '/kmCashstatements';
  FkmItem := '/kmItem';
  FkmVariantId := '/kmVariantId';
  FkmItemSale := '/kmItemSale';
  FkmItemMove := '/kmItemMove';
  FkmItemStock := '/kmItemStock';
  FkmItemAccess := '/kmItemAccess';
  FkmPurchaseHeader := '/kmPurchaseHeader';
  FkmPurchaseInvoiceLines := '/kmPurchaseInvoiceLines';
  FkmDocumentApproval := '/kmDocumentApproval';
  FkmVendor := '/kmVendor';
end;

{TBusinessCentral_Error_Response}

constructor TBusinessCentral_Error_Response.Create;
begin
  inherited;
  FError := TBusinessCentral_Error_Response_Body.Create;
end;

destructor TBusinessCentral_Error_Response.Destroy;
begin
  FError.Free;
  inherited;
end;

{TkmCashstatement}

function TkmCashstatement.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(Fodata_etag, '\', '', []);
end;

{TBCCompany}

{TkmItems}

constructor TkmItems.Create;
begin
  FValue := TObjectList<TkmItem>.Create;
end;

destructor TkmItems.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmItem}

function TkmItem.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TRoot}

constructor TkmVariantIds.Create;
begin
  FValue := TObjectList<TkmVariantId>.Create;
end;

destructor TkmVariantIds.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmVariantId}

function TkmVariantId.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmItemSales}

constructor TkmItemSales.Create;
begin
  FValue := TObjectList<TkmItemSale>.Create;
end;

destructor TkmItemSales.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmItemSale}

function TkmItemSale.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmItemMoves}

constructor TkmItemMoves.Create;
begin
  FValue := TObjectList<TkmItemMove>.Create;
end;

destructor TkmItemMoves.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmItemMove}

function TkmItemMove.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmItemStock}

function TkmItemStock.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmItemStocks}

constructor TkmItemStocks.Create;
begin
  FValue := TObjectList<TkmItemStock>.Create;
end;

destructor TkmItemStocks.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmItemAccess}

function TkmItemAccess.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmItemAccesss}

constructor TkmItemAccesss.Create;
begin
  FValue := TObjectList<TkmItemAccess>.Create;
end;

destructor TkmItemAccesss.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmPurchaseHeaders}

constructor TkmPurchaseHeaders.Create;
begin
  FValue := TObjectList<TkmPurchaseHeader>.Create;
end;

destructor TkmPurchaseHeaders.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmPurchaseInvoiceLines}

constructor TkmPurchaseInvoiceLines.Create;
begin
  FValue := TObjectList<TkmPurchaseInvoiceLine>.Create;
end;

destructor TkmPurchaseInvoiceLines.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmPurchaseHeader}

function TkmPurchaseHeader.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmPurchaseInvoiceLine}

function TkmPurchaseInvoiceLine.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmDocumentApproval}

function TkmDocumentApproval.GetapprovalStatusAsInteger: integer;
begin
  if (AnsiUpperCase(FApprovalStatus) = AnsiUpperCase('Awaiting')) then
  begin
    result := 0;
  end
  else if (AnsiUpperCase(FApprovalStatus) = AnsiUpperCase('Approved')) then
  begin
    result := 1;
  end
  else if (AnsiUpperCase(FApprovalStatus) = AnsiUpperCase('Rejected')) then
  begin
    result := 2;
  end
  else
  begin
    result := 99;
  end;
end;

function TkmDocumentApproval.GetapprovalStatusAsString(aApprovalStatus: integer): string;
begin
  if (aApprovalStatus = 0) then
  begin
    result := 'Awaiting';
  end
  else if (aApprovalStatus = 1) then
  begin
    result := 'Approved';
  end
  else if (aApprovalStatus = 2) then
  begin
    result := 'Rejected';
  end
  else
  begin
    result := 'Approved';
  end;
end;

function TkmDocumentApproval.GetdocumentType: integer;
begin
  if TryStrToInt(FDocumentType, result) then
  begin
  end
  else
  begin
    result := 0;
  end;
end;

function TkmDocumentApproval.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

{TkmDocumentApprovals}

constructor TkmDocumentApprovals.Create;
begin
  FValue := TObjectList<TkmDocumentApproval>.Create;
end;

destructor TkmDocumentApprovals.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmVendors}

constructor TkmVendors.Create;
begin
  FValue := TObjectList<TkmVendor>.Create;
end;

destructor TkmVendors.Destroy;
begin
  FValue.Free;
  inherited;
end;

{TkmVendor}

function TkmVendor.GeteTagToUSeInHeader: string;
begin
  // Do remoce any \ from result
  result := StringReplace(FOdataEtag, '\', '', []);
end;

end.
