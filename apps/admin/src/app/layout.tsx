import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Tamale Delivery — Staff & Dispatcher Hub',
  description: 'Operations, dispatching, fleet management, and ledger review for Tamale Delivery Service',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
