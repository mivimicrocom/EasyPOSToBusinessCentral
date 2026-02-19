# Teknisk Dokumentation: Kostpris Synkronisering (Cost Price from BC)

**Retning:** Business Central → EasyPOS ⬅️  
**Metode:** DoSyncCostPriceFromBusinessCentral  
**API Endpoint:** kmCostprice (GET)  
**Batch Size:** 200 varianter per kørsel  

---

## ⚠️ ADVARSEL

Denne synkronisering er UNIK fordi den:
- Kører MODSAT retning (BC → EP)
- Opdaterer DIREKTE lagerbeholdning via reguleringer
- Kan forårsage data-inkonsistens hvis fejlkonfigureret
- Skal håndteres med STOR forsigtighed

---

## Oversigt

Henter kostpriser fra Business Central og opdaterer dem i EasyPOS. Processen opdaterer både kostpris OG lagerbeholdning ved at:
1. Fjerne alt lager (negativregulering)
2. Sætte ny kostpris
3. Tilføje lager tilbage (positivregulering)

Dette sikrer at vejet kostpris beregnes korrekt, men er RISIKABELT!

---

## Se også

- Internal/Sync_5_Costprice_From_BC.md - Detaljeret dokumentation
- README.md - Projekt oversigt
