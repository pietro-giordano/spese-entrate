// Valori ammessi dalle colonne "a scelta" dello schema.
// Nel database sono salvati come testo con il nome del valore (es. 'expense'),
// quindi rinominare un valore richiede una migrazione.

enum WalletType { cash, checking, card, savings, investment, other }

enum CategoryKind { expense, income }

enum TransactionType { expense, income, transfer, adjustment }

enum TransactionStatus { confirmed, pending }

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

enum RecurrenceMode { auto, confirm }

enum RecurrenceExceptionKind { skip }

enum OutboxOp { upsert, delete }
