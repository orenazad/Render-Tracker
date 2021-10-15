const functions = require("firebase-functions");
const {PubSub} = require("@google-cloud/pubsub");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const {CloudTasksClient} = require("@google-cloud/tasks");
const client = new CloudTasksClient();

const location = "us-central1";
const queue = "REDACTED";
const projectId = "REDACTED";

admin.initializeApp();


exports.sendDoneNotification = functions.database.ref("/users/{uid}/{index}/RenderStatus")
    .onUpdate(async (change, context) => {
      const uid = context.params.uid;
      const index = context.params.index;
      if (change.after.val() != 3019 && (change.before.val() != 3015 || change.before.val() != 3016)) {
        return functions.logger.log("Item was not done yet!");
      }
      functions.logger.log("Some Item is done!");

      // Get the list of device notification tokens.
      const getDeviceTokensPromise = admin.database()
          .ref(`/utils/${uid}/notificationTokens`).once("value");

      const getCompNamePromise = admin.database().ref(`/users/${uid}/${index}/CompName`).once("value");
      const getProjectNamePromise = admin.database().ref(`/utils/${uid}/ProjectName`).once("value");

      const results = await Promise.all([getDeviceTokensPromise, getCompNamePromise, getProjectNamePromise]);
      const tokensSnapshot = results[0];
      const compName = results[1].val();
      const projectName = results[2].val();

      // Check if there are any device tokens.
      if (!tokensSnapshot.hasChildren()) {
        return functions.logger.log(
            "There are no notification tokens to send to.",
        );
      }
      functions.logger.log(
          "There are",
          tokensSnapshot.numChildren(),
          "tokens to send notifications to.",
      );

      // Notification details.
      const payload = {
        notification: {
          title: `${projectName}`,
          body: `${compName} is done rendering.`,
          sound: "default",
        },
      };

      // Listing all tokens as an array.
      const tokens = Object.keys(tokensSnapshot.val());
      // Send notifications to all tokens.
      const response = await admin.messaging().sendToDevice(tokens, payload);
      // For each message check if there was an error.
      const tokensToRemove = [];
      response.results.forEach((result, index) => {
        const error = result.error;
        if (error) {
          functions.logger.error(
              "Failure sending notification to",
              tokens[index],
              error,
          );
          // Cleanup the tokens who are not registered anymore.
          if (error.code === "messaging/invalid-registration-token" ||
              error.code === "messaging/registration-token-not-registered") {
            tokensToRemove.push(tokensSnapshot.ref.child(tokens[index]).remove());
          }
        }
      });
      return Promise.all(tokensToRemove);
    });

// Instantiates a client
const pubsubClient = new PubSub({
  projectId: projectId,
});


function isAuthorized(req) {
  // Check authorization header
  if (!req.headers.authorization || !req.headers.authorization.startsWith("Bearer ")) {
    return false;
  }
  const authToken = req.headers.authorization.split("Bearer ")[1];
  if (authToken !== "REDACTED") {
    return false;
  }

  return true;
}


// Respond to incoming message
exports.incomingWebhook = functions.https.onRequest((req, res) => {
  // Only allow POST requests
  if (req.method !== "POST") {
    return res.status(403).send("Forbidden");
  }

  // Make sure the authorization key matches what we
  // set in the RevenueCat dashboard
  if (!isAuthorized(req)) {
    console.log("Unauthorized");
    return res.status(401).send("Unauthorized");
  }

  const event = req.body.event;

  let topic = "";


  // Check for the event types that you want to respond to
  // You may only need a subset of these events
  switch (event.type) {
    case "INITIAL_PURCHASE":
      topic = "rc-initial-purchase";
      break;
    case "NON_RENEWING_PURCHASE":
      topic = "rc-non-renewing-purchase";
      break;
    case "RENEWAL":
      topic = "rc-renewal";
      break;
    case "PRODUCT_CHANGE":
      topic = "rc-product-change";
      break;
    case "CANCELLATION":
      topic = "rc-cancellation";
      break;
    case "BILLING_ISSUE":
      topic = "rc-billing-issue";
      break;
    case "SUBSCRIBER_ALIAS":
      topic = "rc-subscriber-alias";
      break;
    default:
      console.log("Unhandled event type: ", event.type);
      return res.sendStatus(200);
  }

  // Set the pub/sub data to the event body
  const dataBuffer = Buffer.from(JSON.stringify(event));

  // Publishes a message
  return pubsubClient.topic(topic)
      .publish(dataBuffer)
      .then(() => res.sendStatus(200))
      .catch((err) => {
        console.error(err);
        res.sendStatus(500);
        return Promise.reject(err);
      });
});

exports.handleInitialPurchase = functions.pubsub.topic("rc-initial-purchase").onPublish((message, context) => {
  // Handle initial purchases of subscription products
  syncClaims(message.json.app_user_id);
  console.log("INITIAL_PURCHASE: ", message.json);
  return null;
});

exports.handleNonRenewingPurchase = functions.pubsub.topic("rc-non-renewing-purchase").onPublish((message, context) => {
  // Handle a non-subscription purchase
  syncClaims(message.json.app_user_id);
  console.log("NON_RENEWING_PURCHASE: ", message.json);
  return null;
});

exports.handleRenewal = functions.pubsub.topic("rc-renewal").onPublish((message, context) => {
  // Handle subscription renewal
  syncClaims(message.json.app_user_id);
  // console.log("RENEWAL: ", message.json);
  return null;
});

exports.handleProductChange = functions.pubsub.topic("rc-product-change").onPublish((message, context) => {
  // Handle subscription product change
  syncClaims(message.json.app_user_id);
  console.log("PRODUCT_CHANGE: ", message.json);
  return null;
});

exports.handleCancellation = functions.pubsub.topic("rc-cancellation").onPublish((message, context) => {
  // Handle subscription cancellations. Note that
  // a subscription may still be active depending
  // on the cancellation type and you shouldn't
  // automatically cut off access.

  functions.logger.log("Canceled Received!");
  const uid = message.json.app_user_id;
  const time = message.json.expiration_at_ms;
  functions.logger.log(`Cancelled UID is ${uid}`);
  createCancelTask(uid, time);
  // syncClaims(message.json.app_user_id);
  // console.log("CANCELLATION: ", message.json);
  return null;
});

exports.handleBillingIssue = functions.pubsub.topic("rc-billing-issue").onPublish((message, context) => {
  // Handle billing issues with subscription renewals
  syncClaims(message.json.app_user_id);
  console.log("BILLING_ISSUE: ", message.json);
  return null;
});

exports.handleSubscriberAlias = functions.pubsub.topic("rc-subscriber-alias").onPublish((message, context) => {
  // Handle subscriber alias events
  syncClaims(message.json.app_user_id);
  console.log("SUBSCRIBER_ALIAS: ", message.json);
  return null;
});

async function syncClaims(uid) {
  try {
    console.time("sync_claims");
    const event = new Date();
    const url = `REDACTED`;
    functions.logger.log(url);
    functions.logger.log(url + "nospace");
    const options = {
      method: "GET",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "REDACTED",
      },
    };
    functions.logger.log("About to fetch: " + url);
    const res = await fetch(url, options);
    const json = await res.json();
    const expireDate = json.subscriber.entitlements["aftereffects"].expires_date;
    const isExpired = event.toISOString() > expireDate;
    await changeClaims();
    console.timeEnd("sync_claims");
  } catch (error) {
    console.log(error);
  }
}

async function changeClaims() {
  const isExpired = false;
  const uid = "REDACTED";
  functions.logger.log("IS EXPIRED: " + isExpired);
  const metadataRef = admin.database().ref('metadata/' + uid);
  console.time("update_claims");
  if (isExpired) {
    admin.auth().setCustomUserClaims(uid, {aftereffects: false});
    metadataRef.set({refreshTime: new Date().getTime()});
    functions.logger.log("Propagating Claims, expired, confirmation that I've redeployed");
  } else {
    admin.auth().setCustomUserClaims(uid, {aftereffects: true});
    // The new custom claims will propagate to the user's ID token the
    // next time a new one is issued.
    metadataRef.set({refreshTime: new Date().getTime()});
    functions.logger.log("Propagating Claims, subscribed confirmation that I've redeployed");
  }
  console.timeEnd("update_claims");
  return true;
}

exports.cancelCallback = functions.https.onRequest((req, res) => {
  functions.logger.log("Callback called!");
  const uid = Buffer.from(req.rawBody, 'base64').toString('ascii');
  functions.logger.log("UID: " + uid);
  try {
    syncClaims(uid);
    res.send(200);
  } catch (error) {
    console.log(error);
    res.sendStatus(500);
  }
});

async function createCancelTask(uid, time) {
  const parent = client.queuePath(projectId, location, queue);
  const url = "REDACTED";
  const payload = uid;

  const expirationAtSeconds = (time / 1000) + 10;

  const task = {
    httpRequest: {
      httpMethod: "POST",
      url,
      body: Buffer.from(payload).toString('base64'),
      headers: {
        'content-type': 'application/octet-stream',
      },
    },
  };

  if (payload) {
    functions.logger.log("Payload has UID: " + payload.uid);
    task.httpRequest.body = Buffer.from(JSON.stringify(payload)).toString('base64');
  }

  if (expirationAtSeconds) {
    task.scheduleTime = {
      seconds: expirationAtSeconds,
    };
  }

  const callOptions = {
    timeout: 30000,
  };

  functions.logger.log("Sending Task");
  functions.logger.log(task);
  const request = {parent, task};
  const [response] = await client.createTask(request, callOptions);
  functions.logger.log(`Created task ${response.name}`);
}


exports.updateClaims = functions.https.onRequest(async (request, response) => {
  console.time("update_claims");
  await admin.auth().setCustomUserClaims("REDACTED", {test: true});
  console.timeEnd("update_claims");
  response.send("Updated Claims");
});