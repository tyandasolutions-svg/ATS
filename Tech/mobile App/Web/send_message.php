<?php
/**
 * Send Message Handler
 * Processes contact form submissions and redirects to WhatsApp
 */

// Security headers
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: index.php');
    exit;
}

// Sanitize inputs
$name = htmlspecialchars(trim($_POST['name'] ?? ''), ENT_QUOTES, 'UTF-8');
$email = filter_var(trim($_POST['email'] ?? ''), FILTER_SANITIZE_EMAIL);
$subject = htmlspecialchars(trim($_POST['subject'] ?? ''), ENT_QUOTES, 'UTF-8');
$message = htmlspecialchars(trim($_POST['message'] ?? ''), ENT_QUOTES, 'UTF-8');

// Validation
$errors = [];

if (empty($name)) {
    $errors[] = 'Name is required';
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors[] = 'Valid email is required';
}

if (empty($subject)) {
    $errors[] = 'Subject is required';
}

if (empty($message)) {
    $errors[] = 'Message is required';
}

if (!empty($errors)) {
    header('Location: index.php?error=' . urlencode(implode(', ', $errors)));
    exit;
}

// Build WhatsApp message
$waMessage = "*New Message from Portfolio*\n\n"
    . "*Name:* {$name}\n"
    . "*Email:* {$email}\n"
    . "*Subject:* {$subject}\n"
    . "*Message:* {$message}";

$waUrl = 'https://wa.me/6282240672011?text=' . urlencode($waMessage);

// Optional: Save to file for backup (create messages directory if needed)
$logDir = __DIR__ . '/messages';
if (!is_dir($logDir)) {
    mkdir($logDir, 0750, true);
}

$logEntry = date('Y-m-d H:i:s') . " | {$name} | {$email} | {$subject} | {$message}\n";
file_put_contents($logDir . '/messages.log', $logEntry, FILE_APPEND | LOCK_EX);

// Redirect to WhatsApp
header('Location: ' . $waUrl);
exit;
