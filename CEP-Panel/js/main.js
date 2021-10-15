var firebase = require("firebase/app");
require("firebase/auth");
require("firebase/database");
const fetch = require('node-fetch');

const firebaseConfig = {
  apiKey: "REDACTED",
  authDomain: "REDACTED",
  databaseURL: "REDACTED",
  projectId: "REDACTED",
  storageBucket: "REDACTED",
  messagingSenderId: "REDACTED",
  appId: "REDACTED",
  measurementId: "REDACTED",
};
firebase.initializeApp(firebaseConfig);

let uid = null;
let oldNumRQItems = 0; 
let oldProjName = "Untitled Project.aep";
let oldArray = "[" + '\n\n' + "]"; 
let intervalHandle = null;
let currentlyRendering = false;

const txtEmail = document.getElementById('txtEmail');
const txtPassword = document.getElementById('txtPassword');

function createUser() {
  const email = txtEmail.value;
  const password = txtPassword.value;
  firebase.auth().createUserWithEmailAndPassword(email, password)
  .then((userCredential) => {   // Signed in 
    var user = userCredential.user;
  })
  .catch((error) => {
    var errorCode = error.code;
    var errorMessage = error.message;
    alert("Error Code: " + errorCode + '\n' + "Error Message: " + errorMessage);
  });
}

function loginUser() {
  const email = txtEmail.value;
  const password = txtPassword.value;
  firebase.auth().signInWithEmailAndPassword(email, password)
  .then((userCredential) => {     // Signed in
    var user = userCredential.user;
  })
  .catch((error) => {
    var errorCode = error.code;
    var errorMessage = error.message;
    alert("Error Code: " + errorCode + '\n' + "Error Message: " + errorMessage);
  });
}

function logoutUser() {
  try {
    firebase.auth().signOut();
    uid = null;
  } catch (err) {
    alert(err);
  }
}

firebase.auth().onIdTokenChanged(function (user) {
  if (user) {
    uid = user.uid;
    user.getIdToken(true);
    user.getIdTokenResult()
      .then((idTokenResult) => {
        if (!!idTokenResult.claims.aftereffects) {
          document.getElementById("NotSubscribed").style.display = "none";
          document.getElementById("loading").style.display = "none";
          document.getElementById("loggedOut").style.display = "none";
          document.getElementById("RenderingDiv").style.display = "none";
          document.getElementById("loggedIn").style.display = "block";
        } else {
          document.getElementById("NotSubscribed").style.display = "block";
          document.getElementById("loading").style.display = "none";
          document.getElementById("loggedOut").style.display = "none";
          document.getElementById("RenderingDiv").style.display = "none";
          document.getElementById("loggedIn").style.display = "none";
        }
      })
      .catch((error) => {
        console.log(error);
      });
    cleanUserDatabase();
    cleanButtons();
    renderButtonListener();
    clearQueueListener();
    writeUserData();
    intervalHandle = setInterval(checkRQChange, 3000);
    document.getElementById("loading").style.display = "none";
    document.getElementById("loggedOut").style.display = "none";
    document.getElementById("RenderingDiv").style.display = "none";
    document.getElementById("loggedIn").style.display = "block";
  } else {
    uid = null;
    var renderButtonRef = firebase
      .database()
      .ref("utils/" + uid + "/RenderButton");
    var clearButtonRef = firebase
      .database()
      .ref("utils/" + uid + "/ClearButton");
    renderButtonRef.off();
    clearButtonRef.off();
    clearInterval(intervalHandle);
    document.getElementById("loading").style.display = "none";
    document.getElementById("loggedIn").style.display = "none";
    document.getElementById("RenderingDiv").style.display = "none";
    document.getElementById("loggedOut").style.display = "block";
  }
});

function forceIDToken() {
  firebase.auth().currentUser.getIdToken(true);
}

function alertEntitlement() {
  const uid = firebase.auth().currentUser.uid;
getEntitlement(uid);
}


function getEntitlement(uid) {
  const event = new Date();
   const url = `REDACTED`;
   const options = {
     method: "GET",
     headers: {
       Accept: "application/json",
       "Content-Type": "application/json",
       Authorization: "REDACTED",
     },
   };
   fetch(url, options)
     .then((res) => res.json())
     .then((json) => json.subscriber.entitlements["aftereffects"].expires_date)
     .then((expireDate) => event.toISOString() > expireDate)
     .then((isExpired) => checkClaim(isExpired))
     .catch((err) => console.error("error:" + err));
 }

function renderButtonListener() {
  var renderButtonRef = firebase
    .database()
    .ref("utils/" + uid + "/RenderButton");
  renderButtonRef.on("value", (snapshot) => {
    const data = snapshot.val();
    if (data == 1) {
      renderAndUpdate();
      firebase
        .database()
        .ref("utils/" + uid + "/")
        .update({
          RenderButton: 0,
        });
    }
  });
}

function clearQueueListener() {
  var clearButtonRef = firebase.database().ref("utils/" + uid + "/ClearButton");
  clearButtonRef.on("value", (snapshot) => {
    const data = snapshot.val();
    if (data == 1) {
      clearQueue()
      firebase
        .database()
        .ref("utils/" + uid + "/")
        .update({
          ClearButton: 0,
        });
    }
  });
}

async function clearQueue() {
  const isRendering = await runJSX("checkRendering");
  if (isRendering == "false" && !currentlyRendering) {
    runJSX("clearQueue");
    writeUserData();
  }
}

function cleanButtons() {
  firebase
    .database()
    .ref("utils/" + uid + "/")
    .update({
      ClearButton: 0,
    });
  firebase
    .database()
    .ref("utils/" + uid + "/")
    .update({
      RenderButton: 0,
    });
}

function cleanUserDatabase() {
  firebase
  .database()
  .ref("users/" + uid + "/")
  .remove();
}

function checkUser() {
  var checkUser = firebase.auth().currentUser;
  alert(checkUser);
  const payload = {
    uid: checkUser.uid,
  }
  const payloadBuffer = Buffer.from(JSON.stringify(payload));
  alert("Buffer:" + payloadBuffer);
  alert("Parsed Buffer: " + JSON.parse(payloadBuffer).uid);
  alert(checkUser.email);
}

async function writeUserData() {
  if (uid == null) {
    return;
  }
  const numRQItems = await runJSX("numRQItems");
  const projName = await runJSX("getProjName");
  const projNameDecoded = decodeURI(projName);
  firebase
    .database()
    .ref("utils/" + uid + "/")
    .update({
      ProjectName: projNameDecoded,
    });
  var index;
  for (index = 1; index <= Math.max(numRQItems, oldNumRQItems); index++) {
    if (index <= numRQItems) {
      const name = await runJSX("getNameFromIndex", index);
      const status = await runJSX("getStatusFromIndex", index);
      firebase
        .database()
        .ref("users/" + uid + "/" + index)
        .update({
          CompName: name,
          RenderStatus: status,
        });
    } else {
      firebase
        .database()
        .ref("users/" + uid + "/" + index)
        .remove();
    }
  }
  oldNumRQItems = numRQItems;
}

async function renderAndUpdate() {
  if (uid == null) {
    return;
  }
  const isRendering = await runJSX("checkRendering");
  if (isRendering != "false") {
    return;
  }
  currentlyRendering = true;
  document.getElementById("loggedIn").style.display = "none";
  document.getElementById("RenderingDiv").style.display = "block";
  await writeUserData();
  const queuedArrayJSON = await runJSX("createArrayAndDequeue");
  const queueArray = JSON.parse(queuedArrayJSON); 
  var fakeIndex = 0;
  for (; fakeIndex < queueArray.length; fakeIndex++) {
    var realIndex = queueArray[fakeIndex];
    firebase
      .database()
      .ref("users/" + uid + "/" + realIndex)
      .update({
        RenderStatus: "3016",
      });
    var updateStatus = await runJSX("queueIndexAndRender", realIndex);
    firebase
      .database()
      .ref("users/" + uid + "/" + realIndex)
      .update({
        RenderStatus: updateStatus,
      });
  }
  currentlyRendering = false;
  document.getElementById("loggedIn").style.display = "block";
  document.getElementById("RenderingDiv").style.display = "none";
}

async function checkRQChange() {
    const newArray = await runJSX("getRQArray");
    const newProjName = await runJSX("getProjName");
    if (newArray != oldArray || oldProjName != newProjName) {
      await writeUserData();
      oldArray = newArray;
      oldProjName = newProjName;
    }
}

function runJSX(scriptName, ...values) {
  return new Promise((resolve, reject) => {
    const args = values.map((value) => `"${value}"`).join(",");
    const csInterface = new CSInterface();
    try {
      csInterface.evalScript(`${scriptName}(${args})`, resolve);
    } catch (err) {
      reject(err);
    }
  });
}

function openhtml() {
  var open = require("open");
  console.log("Opening Website");
  open("https://www.rendertracker.com");
}