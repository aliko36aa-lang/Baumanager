<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: https://alem-facility.de');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON']);
    exit;
}

// Pflichtfelder prüfen
$vorname  = trim($data['vorname']  ?? '');
$nachname = trim($data['nachname'] ?? '');
$tel      = trim($data['tel']      ?? '');

if (!$vorname || !$nachname || !$tel) {
    http_response_code(400);
    echo json_encode(['error' => 'Pflichtfelder fehlen']);
    exit;
}

// Optionale Felder
$email    = trim($data['email']    ?? '');
$leistung = trim($data['leistung'] ?? 'Nicht angegeben');
$adresse  = trim($data['adresse']  ?? 'Nicht angegeben');
$nachricht = trim($data['nachricht'] ?? '');

// Eingaben bereinigen (E-Mail-Injection verhindern)
$clean = fn($s) => str_replace(["\r", "\n", "Content-Type:", "Bcc:", "Cc:"], '', $s);

$vorname   = $clean($vorname);
$nachname  = $clean($nachname);
$tel       = $clean($tel);
$email     = $clean($email);
$leistung  = $clean($leistung);
$adresse   = $clean($adresse);
$nachricht = $clean($nachricht);

// E-Mail zusammenbauen
$to      = 'info@alem-facility.de';
$subject = 'Neue Anfrage: ' . $vorname . ' ' . $nachname;

$body  = "Neue Anfrage über die Website\n";
$body .= str_repeat('-', 40) . "\n\n";
$body .= "Name:       " . $vorname . ' ' . $nachname . "\n";
$body .= "Telefon:    " . $tel . "\n";
if ($email) {
    $body .= "E-Mail:     " . $email . "\n";
}
$body .= "Leistung:   " . $leistung . "\n";
$body .= "Objekt:     " . $adresse . "\n";
if ($nachricht) {
    $body .= "\nNachricht:\n" . $nachricht . "\n";
}
$body .= "\n" . str_repeat('-', 40) . "\n";
$body .= "Gesendet am: " . date('d.m.Y H:i') . " Uhr\n";

$headers  = "From: website@alem-facility.de\r\n";
$headers .= "Reply-To: " . ($email ?: 'keine@angabe.de') . "\r\n";
$headers .= "MIME-Version: 1.0\r\n";
$headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

$sent = mail($to, '=?UTF-8?B?' . base64_encode($subject) . '?=', $body, $headers);

if ($sent) {
    http_response_code(200);
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Mail konnte nicht gesendet werden']);
}
