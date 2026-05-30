import 'package:flutter/material.dart';
import '../models/account.dart';

/// Sample vault shown on first run (mirrors the prototype's SEED_ACCOUNTS).
const List<Account> kSeedAccounts = [
  Account(id: 'a1', issuer: 'Google', label: 'alex.rivera@gmail.com', secret: 'JBSWY3DPEHPK3PXP', logo: 'google', color: Color(0xFF4285F4)),
  Account(id: 'a2', issuer: 'GitHub', label: 'alexrivera', secret: 'KRSXG5CTMVRXEZLU', logo: 'github', color: Color(0xFFE6EDF3)),
  Account(id: 'a3', issuer: 'Coinbase', label: 'alex.rivera@gmail.com', secret: 'MFRGGZDFMZTWQ2LK', logo: 'coinbase', color: Color(0xFF1652F0)),
  Account(id: 'a4', issuer: 'Amazon AWS', label: 'alex@bitanon.dev', secret: 'NB2W45DFOIZA====', logo: 'aws', color: Color(0xFFFF9900)),
  Account(id: 'a5', issuer: 'Dropbox', label: 'alex.rivera@gmail.com', secret: 'ONXW2ZJANRXXEZLT', logo: 'dropbox', color: Color(0xFF0061FF)),
  Account(id: 'a6', issuer: 'Discord', label: 'alexr#4417', secret: 'PFXXK4DBMVZWK5DI', logo: 'discord', color: Color(0xFF5865F2)),
  Account(id: 'a7', issuer: 'Cloudflare', label: 'ops@bitanon.dev', secret: 'QFXGS5DJMVZWK4TF', logo: 'cloudflare', color: Color(0xFFF6821F)),
  Account(id: 'a8', issuer: 'Microsoft', label: 'alex@outlook.com', secret: 'RFXGS43JMFZWK4TG', logo: 'microsoft', color: Color(0xFF5E5E5E)),
  Account(id: 'a9', issuer: 'Figma', label: 'alex.rivera@gmail.com', secret: 'SFXGS43JNFZWK4TH', logo: 'figma', color: Color(0xFFA259FF)),
  Account(id: 'a10', issuer: 'Binance', label: 'alexr_trades', secret: 'TFXGS43JNFZWQ4TI', logo: 'binance', color: Color(0xFFF0B90B)),
];

/// Accounts surfaced in the Google Authenticator batch-import flow.
const List<Account> kImportAccounts = [
  Account(id: 'i1', issuer: 'Slack', label: 'alex@bitanon.dev', secret: 'UFXGS43JNFZWQ4TJ', logo: 'slack', color: Color(0xFF611F69)),
  Account(id: 'i2', issuer: 'Notion', label: 'alex.rivera@gmail.com', secret: 'VFXGS43JNFZWQ4TK', logo: 'notion', color: Color(0xFFE6EDF3)),
  Account(id: 'i3', issuer: 'Stripe', label: 'alex@bitanon.dev', secret: 'WFXGS43JNFZWQ4TL', logo: 'stripe', color: Color(0xFF635BFF)),
  Account(id: 'i4', issuer: 'PayPal', label: 'alex.rivera@gmail.com', secret: 'XFXGS43JNFZWQ4TM', logo: 'paypal', color: Color(0xFF0070E0)),
  Account(id: 'i5', issuer: 'Twitch', label: 'alexr_live', secret: 'YFXGS43JNFZWQ4TN', logo: 'twitch', color: Color(0xFF9146FF)),
];

/// The account "detected" by the simulated QR scanner.
const Account kScanResult = Account(
  id: 'scan1',
  issuer: 'Reddit',
  label: 'u/alex_rivera',
  secret: 'ZGXGS43JNFZWQ4TO',
  logo: 'reddit',
  color: Color(0xFFFF4500),
);
