const crypto = require('crypto');

const generateReceipt = async (event) => {
  const body = JSON.parse(event.body || '{}');

  // Validate required fields
  if (!body.orderId || body.amount === undefined) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        error: 'orderId and amount are required'
      })
    };
  }

  // Generate a unique receipt ID
  const receiptId = crypto.randomUUID();

  // Build the receipt
  const receipt = {
    receiptId,
    orderId: body.orderId,
    amount: body.amount,
    currency: body.currency || process.env.DEFAULT_CURRENCY,
    timestamp: new Date().toISOString(),
    status: 'generated'
  };

  console.log(
    `[kk-receipts] Receipt generated for order ${receipt.orderId}`
  );

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(receipt)
  };
};

const processReceiptUpload = async (event) => {
  for (const record of event.Records || []) {
    const bucketName = record.s3.bucket.name;
    const objectKey = decodeURIComponent(
      record.s3.object.key.replace(/\+/g, ' ')
    );
    const objectSize = record.s3.object.size;
    const eventTime = record.eventTime;

    // receipt-ORD-001.json -> ORD-001
    const orderId = objectKey
      .replace(/^receipt-/, '')
      .replace(/\.json$/, '');

    const logEntry = {
      bucketName,
      objectKey,
      objectSize,
      eventTime,
      orderId,
      processedAt: new Date().toISOString()
    };

    console.log(JSON.stringify(logEntry));
  }
};
module.exports = { generateReceipt, processReceiptUpload };
