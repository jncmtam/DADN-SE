import 'package:flutter/material.dart';

// running backend on local
// const apiUrl = 'http://10.28.129.183:8080/api';
// hosting backend server on ngrok
const apiUrl =
    'localhost:8080/api';
const websocketUrl =
    'wss://3975-2402-800-6327-5c1-28ea-69cc-7e58-734f.ngrok-free.app/api';

////////////// COLORS ////////////////

// base color of the app
const Color kBase0 = Color(0xFFF1F8E8); // 80%
const Color kBase1 = Color(0xFFD8EFD3); // 60%
const Color kBase2 = Color(0xFF1E695A); // 20%
const Color kBase3 = Color(0xFFF4D793); // 5%
const Color kBase4 = Color(0xFFD1E0D8);
const Color kBase5 = Color(0xFFA94A4A); // 5%

// status color
const Color successStatus = Color(0xFF508D4E);
const Color failStatus = Color(0xFFFA7070);
const Color warningStatus = Color(0xFFCEAD24);
const Color debugStatus = Color(0xFFEE60AC);
const Color disableStatus = Color(0xFFEBEBE4);
const Color loadingStatus = kBase2;

// background color
const Color lappBackground = kBase0;
const Color lappBarBackground = kBase2;
const Color lnavBarBackground = kBase2;
const Color lpopupBackground = kBase1;
const Color lcardBackground = kBase4;
const Color ldisableBackground = disableStatus;

// text color
const Color lPrimaryText = kBase2;
const Color lSecondaryText = Color(0xFF895BB6);
const Color lNormalText = Colors.black54;
const Color lSectionTitle = kBase5;
const Color lCardTitle = kBase2;
const Color lDisableText = Color.fromARGB(255, 100, 100, 100);
const Color lAppBarTitle = kBase3;
const Color lAppBarContent = kBase0;

// icon color
const Color selectedTab = kBase3;
const Color unselectedTab = kBase0;

// button color
const Color confirmButton = kBase2;
const Color cancelButton = failStatus;
const Color logoutButton = failStatus;
// const Color addButton = Color(0xFF365486);
const Color lOnMode = kBase2;
const Color lOffMode = Color(0xFF535252);
const Color lAutoMode = Color(0xFF895BB6);
const Color lEnableMode = kBase2;

const Color primaryButton = kBase2;
const Color primaryButtonContent = kBase0;
const Color secondaryButton = kBase1;
const Color secondaryButtonContent = kBase2;

////////////// SIZES /////////////////

// font size
const double lAppBarFontSize = 20;
const double lAppBarHeight = 60;
