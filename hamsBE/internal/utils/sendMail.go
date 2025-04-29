package utils

import (
	"fmt"
	"os"

	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

// SendEmail sends an email to the specified recipient using SendGrid with an HTML body.
func SendEmail(to, subject, body, otp string) error {
    // Validate environment variables
    fromEmail := os.Getenv("EMAIL")
    sendgridAPIKey := os.Getenv("SENDGRID_API_KEY")

    if fromEmail == "" {
        return fmt.Errorf("EMAIL environment variable is not set")
    }
    if sendgridAPIKey == "" {
        return fmt.Errorf("SENDGRID_API_KEY environment variable is not set")
    }

    if sendgridAPIKey == "" {
        return fmt.Errorf("SENDGRID_API_KEY environment variable is not set")
    }

    // Validate the 'to' email (basic check)
    if to == "" {
        return fmt.Errorf("recipient email address cannot be empty")
    }

    // Set up the email
    from := mail.NewEmail("HamsterCare", fromEmail)
    toEmail := mail.NewEmail("", to)

    // HTML body with OTP and Hamster theme
    htmlBody := `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Email Verification</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #F7F7F7;
            padding: 20px;
        }

        .container {
            max-width: 600px;
            margin: 0 auto;
            background: #FFFFFF;
            padding: 40px;
            border-radius: 12px;
            
            box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1);
            text-align: center;
        }

        .header {
            background: #FFCC80;
            padding: 20px;
            border-top-left-radius: 12px;
            border-top-right-radius: 12px;
        }

        .header h2 {
            font-size: 24px;
            font-weight: bold;
            color: #D84315;
            margin-bottom: 10px;
        }

        .content {
            padding: 20px;
            background-color: #fbe7c5;
        }

        .content p {
            font-size: 16px;
            color: #333333;
            margin-bottom: 20px;
        }

        .otp-code {
            font-size: 36px;
            font-weight: bold;
            color: #D84315;
            background: #FFE0B2;
            display: inline-block;
            padding: 20px 40px;
            border-radius: 6px;
            margin: 20px 0;
        }

        .footer {
            font-size: 12px;
            color: #5D4037;
            margin-top: 20px;
        }

        .hamster-img {
            width: 100px;
            height: auto;
            margin: 10px auto;
            display: block;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>` + subject + `</h2>
        </div>
        <div class="content">
            <p>` + body + `</p>
            <div class="otp-code">` + otp + `</div>
            <p>This OTP is valid for 5 minutes.</p>
        </div>
        <div class="footer">
            <p>If you did not request this OTP, please ignore this email.</p>
        </div>
    </div>
</body>
</html>
`

    // Create the email message
    message := mail.NewSingleEmail(from, subject, toEmail, "", htmlBody)
    client := sendgrid.NewSendClient(sendgridAPIKey)

    // Send the email
    response, err := client.Send(message)
    if err != nil {
        return fmt.Errorf("failed to send email: %w", err)
    }
    if response.StatusCode >= 300 {
        return fmt.Errorf("failed to send email, status code: %d, body: %s", response.StatusCode, response.Body)
    }

    return nil
}