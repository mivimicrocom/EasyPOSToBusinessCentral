# Guide: Vare Synkronisering til Business Central

**For EasyPOS Brugere**

---

## 📋 Hvad Synkroniseres?

Når du arbejder med varer i EasyPOS, synkroniseres følgende automatisk til Business Central:

✅ Varebeskrivelser  
✅ Varegrupper og kategorier  
✅ Leverandør-information  
✅ Model og varenumre  
✅ Farver, størrelser og længder (varianter)  
✅ Stregkoder (EAN)  

❌ **OBS:** Priser synkroniseres IKKE fra EasyPOS til Business Central  
→ Priser hentes fra Business Central til EasyPOS

---

## 🔄 Hvornår Sker Synkronisering?

### Automatisk Synkronisering

Varer synkroniseres automatisk når du:

1. **Redigerer vare-oplysninger i EasyPOSKontor:**
   - Ændrer varenavn eller beskrivelse
   - Skifter varegruppe
   - Opdaterer leverandør-information
   - Ændrer model eller varenummer
   - Tilføjer eller ændrer kategorier

2. **Arbejder med varianter:**
   - Opretter ny variant (farve/størrelse)
   - Ændrer variant-beskrivelser
   - Opdaterer stregkoder

3. **Importerer varer via API:**
   - Når vare-information opdateres via integration
   - **MEN IKKE** når kun priser opdateres

### Manuel Synkronisering

Hvis en vare ikke synkroniseres automatisk, kan du:

1. Åbn varen i EasyPOSKontor
2. Højreklik på varen
3. Vælg **"Synkroniser vare imod Business Central"**
4. Varen markeres til synkronisering ved næste kørsel

---

## ⏱️ Hvor Hurtigt Sker Det?

**Ikke real-time!** Synkronisering sker typisk:

- **Dagligt kl. 22:00** (eller andet aftalt tidspunkt)
- **Eller hvert 15. minut** (afhængig af opsætning)

Din vare vil blive synkroniseret ved næste planlagte kørsel.

---

## ✅ Hvad Sker Der IKKE?

### Priser

❌ Kostpriser synkroniseres IKKE fra EasyPOS → Business Central  
✅ Kostpriser hentes fra Business Central → EasyPOS

**Hvorfor?**  
Business Central er master for priser. Prisændringer skal ske i BC først.

### Lagerbeholdning

❌ Vareantal synkroniseres IKKE automatisk  
✅ Salgstransaktioner og flytninger synkroniseres (særskilt proces)

### Billeder

❌ Varebilleder synkroniseres IKKE  
→ Billeder håndteres separat i hvert system

---

## 🔍 Hvordan Tjekker Jeg Om En Vare Synkroniseres?

### I EasyPOSKontor

1. Åbn varen
2. Se på feltet **"BC_UPDATEDATE"** nederst i varevinduet
3. Dato viser hvornår varen sidst blev markeret til synkronisering

**Eksempel:**
- BC_UPDATEDATE: `18-12-2025 13:30:00`
- → Varen synkroniseres ved næste kørsel efter dette tidspunkt

---

## 🎯 Hvad Trigger IKKE Synkronisering?

For at undgå unødvendige opdateringer i Business Central, synkroniseres varer **IKKE** når:

❌ Du kun ændrer priser  
❌ Du opdaterer interne noter eller kommentarer  
❌ Du ændrer lagerbeholdning  
❌ Du tilføjer billeder  
❌ Du arbejder i kassesystemet (EasyPOSSalg)  

---

## 💡 Typiske Scenarier

### Scenarie 1: Ny Vare

**Du gør:**
1. Opretter ny vare i EasyPOSKontor
2. Udfylder varenavn, varegruppe og leverandør

**Hvad sker:**
- ✅ Vare markeres automatisk til synkronisering
- ✅ Synkroniseres til BC ved næste kørsel
- ✅ Varen er tilgængelig i BC samme dag/nat

### Scenarie 2: Opdater Varenavn

**Du gør:**
1. Åbner vare i EasyPOSKontor
2. Ændrer varenavn fra "Blå Trøje" til "Blå T-shirt"
3. Gemmer

**Hvad sker:**
- ✅ BC_UPDATEDATE opdateres automatisk til "nu"
- ✅ Varen synkroniseres til BC ved næste kørsel
- ✅ Varenavn opdateres i BC

### Scenarie 3: Opdater Kun Pris

**Du gør:**
1. Importerer nye kostpriser via integration
2. Kun pris-felter opdateres

**Hvad sker:**
- ❌ BC_UPDATEDATE opdateres IKKE
- ❌ Varen synkroniseres IKKE til BC
- ✅ Korrekt! Priser skal ikke til BC

### Scenarie 4: Tilføj Ny Variant

**Du gør:**
1. Åbner vare i EasyPOSKontor
2. Tilføjer ny farve: "Rød"
3. Gemmer

**Hvad sker:**
- ✅ BC_UPDATEDATE opdateres automatisk
- ✅ Hele varen (inkl. ALLE varianter) synkroniseres til BC
- ✅ Ny variant tilgængelig i BC

### Scenarie 5: Vare Synkroniserer Ikke

**Problem:**
Vare bliver ikke synkroniseret selvom du har rettet den

**Løsning:**
1. Åbn varen i EasyPOSKontor
2. Højreklik → "Synkroniser vare imod Business Central"
3. Check BC_UPDATEDATE er opdateret
4. Vent til næste kørsel

---

## 📞 Support

**Vare synkroniseres ikke?**

1. Check BC_UPDATEDATE er opdateret
2. Vent til efter næste planlagte kørsel (f.eks. kl. 22)
3. Tjek varen i Business Central
4. Kontakt support hvis problemet fortsætter

**Hvad skal support bruge?**
- Varenummer (PLU_NR)
- BC_UPDATEDATE værdi
- Hvad du ændrede
- Hvornår du ændrede det

---

## 📚 Opsummering

| Handling | Synkroniseres? | Hvornår? |
|----------|---------------|----------|
| Ret varenavn | ✅ Ja | Næste kørsel |
| Skift varegruppe | ✅ Ja | Næste kørsel |
| Opdater leverandør | ✅ Ja | Næste kørsel |
| Tilføj variant | ✅ Ja | Næste kørsel |
| Ret pris | ❌ Nej | Ikke relevant |
| Tilføj billede | ❌ Nej | Håndteres separat |
| Salg i kasse | ❌ Nej | Anden proces |
| Manuel synk | ✅ Ja | Næste kørsel |

---

**Sidst opdateret:** 18. december 2025  
**Version:** 1.0  
**Gælder for:** EasyPOS v8.03+
