# Render-Tracker<!-- omit in toc -->

I've spent a lot of time working in After Effects and Premiere Pro. As much as I love these programs, I've always felt they were lacking important functionality when it came to communicating encoding progress with users. As a computer science student at UC Berkeley, I decided to take the challenge myself and develop a solution. I created Render Tracker, a full-stack iOS application which let users manage and track the render queue, and recieve push notifications upon render completion!

I wanted to detail my experience and walkthrough the process for anyone interested in full-stack development, developing for Adobe applications, or for anyone who wants a (hopefully) fascinating read! If you are only interested in one part of this project, feel free to skip around to wherever you'd like.

---
<p align="middle">
  <img src="https://user-images.githubusercontent.com/70298555/137476590-3db878a1-594a-4bbd-aa1d-308527297e76.png" width="250" alt="Screenshot of Render Tracker" />
  <img height="" hspace="30"/>
  <img src="https://user-images.githubusercontent.com/70298555/137480416-650984ea-ea7b-4cec-93b1-e697e9359cc7.png" width="250" alt="Screenshot of Render Tracker Notifications" />
</p>

---

- [Intro: Developing for After Effects](#intro-developing-for-after-effects)
  - [**Adobe ExtendScript**](#adobe-extendscript)
  - [**Common Extensibility Platform**](#common-extensibility-platform)
  - [**After Effects Plug-In**](#after-effects-plug-in)
  - [**Choosing a Development Platform**](#choosing-a-development-platform)
- [Chapter 1: Starting with ExtendScript](#chapter-1-starting-with-extendscript)
- [Chapter 2: CEP Party Time](#chapter-2-cep-party-time)
  - [**Pulling Data with ExtendScript**](#pulling-data-with-extendscript)
  - [**Journey Into Callback Hell**](#journey-into-callback-hell)
  - [**A Better Way**](#a-better-way)
  - [**CEP Functions**](#cep-functions)
  - [**Performance Woes**](#performance-woes)
  - [**A Spoonful of HTML and CSS**](#a-spoonful-of-html-and-css)
- [Chapter 3: Into The Cloud!](#chapter-3-into-the-cloud)
  - [**What is Firebase?**](#what-is-firebase)
  - [**Realtime Database**](#realtime-database)
  - [**Push Notifications**](#push-notifications)
- [Chapter 4: Down the iOS Rabbit-Hole](#chapter-4-down-the-ios-rabbit-hole)
- [**Disaster Strikes, Concluding Thoughts**](#disaster-strikes-concluding-thoughts)

---

## Intro: Developing for After Effects

Adobe primarily provides three avenues (with a fourth on the way!) to develop for creative cloud applications, all at varying levels of complexity and capability. 

### **Adobe ExtendScript**

Extendscript is an extended form of Javascript (following the ECMA-262 specification) developed by Adobe for use in After Effects and other Adobe applications. The [After Effects Scripting Guide](https://ae-scripting.docsforadobe.dev) contains all the documentation needed to get you started in developing scripts for AE! ExtendScript is most often used to quickly  write simple scripts to save time and reduce repetitive tasks, but can also be used for more complex projects.

### **Common Extensibility Platform**

The Common Extensibility Platform, or CEP for short, allows for another step of complexity. A CEP extension is kind of like a little chrome browser running inside your Adobe software, allowing you to develop a web application within most Creative Cloud programs. CEP panels are great for when you want to create an advanced UI/UX, use NodeJS modules or other JS libraries, and connect ExtendScript scripts in a more complex manner. Importantly, CEP extensions still use ExtendScript to interact with After Effects, so make sure to check out the [scripting guide](https://ae-scripting.docsforadobe.dev) to understand the capabilities that come with ExtendScript. The [Adobe CEP Team](https://github.com/Adobe-CEP) has published [some guides on getting started](https://github.com/Adobe-CEP/Getting-Started-guides) as well as some [sample extensions and code](https://github.com/Adobe-CEP/Samples).

### **After Effects Plug-In**

Adobe publishes a full SDK for virtually all Creative Cloud applications. Plugins require development in C++ and are  the most time consuming and complex to develop, but are also incredibly capable and rewarding. Plug-ins unlock the ability to interact with almost every piece of After Effects and other CC software. The [AE SDK guide](https://ae-plugins.docsforadobe.dev) covers much of what's possible with AE plugins and how to get started.

### **Choosing a Development Platform** 

Experiment! There are pros and cons to each development platform, and unless a feature you would like to implement strictly requires one, I would reccommend trying them all and deciding which can will allow you to best achieve your goals.

I initially started developing Render Track as a C++ Plugin, however, the `RenderQueueMonitorSuite` needed to properly watch the render queue [hasn't been working in recent versions of After Effects.](https://community.adobe.com/t5/after-effects-discussions/aegp-registerlistener-in-ae-sdk-2017-1/m-p/12046478#M171237) So I switched to a CEP Panel which ended up having some really nice benefits over developing a plugin!


---

## Chapter 1: Starting with ExtendScript

As mentioned, the [After Effects Scripting Guide](https://ae-scripting.docsforadobe.dev) is a great resource to figure out exactly what is available to you through ExtendScript. For Render Tracker, what's important were the [RenderQueue Object](https://ae-scripting.docsforadobe.dev/renderqueue/renderqueue/) and [RenderQueueItem Object](https://ae-scripting.docsforadobe.dev/renderqueue/renderqueueitem/).

I started off creating simple functions to familiarize myself with ExtendScript and experiment with what's possible through scripting. 

```JSX
function numRQItems() {
  return app.project.renderQueue.numItems;
}

function getNameFromIndex(index) {
  var name = app.project.renderQueue.item(+index).comp.name;
  return name;
}

function getStatusFromIndex(index) {
  var status = app.project.renderQueue.item(+index).status;
  return status;
}
```

>Babysteps! These first three functions I wrote were as simple as they get. They individually return the number of items in the Render Queue, and the name and status of each item. 

Soon after I wrote some more complex functions in order to execute different tasks needed by the extension.

```JSX
function getRQArray() {
  var numItems = app.project.renderQueue.numItems;
  var RQItems = [];
  for (var i = 1; i <= numItems; i++) {
    var status = app.project.renderQueue.item(i).status;
    var name = app.project.renderQueue.item(i).comp.name;
    RQItems.push([name, status]);
  }
  return JSON.stringify(RQItems);
}
```

>This function returns an array of all the items in the Render Queue, with the name and render status of each item.

ExtendScript can only return `strings` back to a CEP panel, so it is neccessary to include `JSON` and `stringify` where needed in order to return more complex objects, like the array returned above.

```JSX
function createArrayAndDequeue() {
  var numItems = app.project.renderQueue.numItems;
  var queuedItems = [];
  for (var i = 1; i <= numItems; i++) {
    if (app.project.renderQueue.item(i).status == RQItemStatus.QUEUED) {
      queuedItems.push(i);
      app.project.renderQueue.item(i).render = false;
    }
  }
  return JSON.stringify(queuedItems);
}
```

Not everything in the Render Queue is ready to be encoded. Some items may have already been finished, purposefully skipped, missing output locations or have failed for various reasons. `createArrayAnddDequeue()` returns an array with the index of all items ***ready for encoding*** and de-queues them so that they can automatically be queued and rendered one at a time. 

ExtendScript functions serve as the foundation for any CEP Extension/Panel. You can view the other ExtendScript functions I wrote for Render Tracker [here LINK NEEDED](LINK).

---
## Chapter 2: CEP Party Time


### **Pulling Data with ExtendScript**

Moving on with our extension, the first challenge is to grab data from our ExtendScript functions and move it into our CEP Panel.

While Adobe provides `csInterface.evalScript()` to run scripts from an extension, it can be quite difficult to implement because it runs *asynchronously*.

This can become a huge headache as your extension continues execution before your script has finished evaluating. Simple functions like this will return undefined.  

```JS
const numRQItems = csInterface.evalScript('numRQItems()');
alert(numRQItems);
```
> `alert()` returns undefined because execution continued before `evalScript()` could return a value.  

### **Journey Into Callback Hell**


Luckily we can use callbacks to fix this! However, for any functions remotely complex this will place us in *callback hell*. 

```JS
csInterface.evalScript('firstFunction()', function(firstResult){
    csInterface.evalScript(`secondFunction(${firstResult})`, function(secondResult){
        csInterface.evalScript(`thirdFunction(${secondResult})`, function(thirdResult){
            csInterface.evalScript(`fourthFunction(${thirdResult})`, function(fourthResult){
                // You get the idea. 
            })
        })
    })
})
```
> `evalScript()` functions can be chained to solve asynchronous execution, but end up creating unreadable code. 

[This great article](https://medium.com/adobetech/using-es6-promises-to-write-async-evalscript-calls-in-photoshop-2ce40f93bd8b) by Steve Kwak discusses this in greater depth and highlights the use of `Promise` as a solution.


### **A Better Way**

This simple but amazing function was written with [MichalD96](https://github.com/MichalD96), another member of the AE development community. As discussed above, it takes advantage of `Promise` in ES6 to make asynchronous `evalScript()` calls work synchronously.

```JS
function runJSX(scriptName, ...values) {
  return new Promise((resolve, reject) => {
    const args = values.map((value) => `"${value}"`).join(",");
    const csInterface = new CSInterface();
    try {
      csInterface.evalScript(`${scriptName}(${args})`, resolve);
    } catch (err) {
      // resolve any errors here
    }
  });
}
```
Using a dedicated function like `runJSX()` to evaluate ExtendScript functions will simplify your code and ease development!

### **CEP Functions**

Now we can finally take a look at some functions which finally join ExtendScript and CEP!

```JS
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
```
> Notably, `app.project.file.name` is an HTML encoded string, so it has to be decoded before being uploaded to the database.

>Notice our beautiful `runJSX()` function from earlier! Without it, this function would be stacked in four callbacks and would be impossible to navigate.

Using some of the basic ExtendScript functions shown earlier, `writeUserData()` pulls render queue & project information out of After Effects and pushes it to an online database. Don't worry about that yet though, it's covered in [Chapter 3: Into The Cloud!](#chapter-3-into-the-cloud)


```JS
async function renderAndUpdate() {
  if (uid == null) {
    return;
  }
  const isRendering = await runJSX("checkRendering");
  if (isRendering != "false") {
    return;
  }
  currentlyRendering = true;
  // Update the panel's visuals to display that rendering has started
  document.getElementById("loggedIn").style.display = "none"; 
  document.getElementById("RenderingDiv").style.display = "block"; 
  await writeUserData();
  const queuedArrayJSON = await runJSX("createArrayAndDequeue");
  const queueArray = JSON.parse(queuedArrayJSON); // array of all queued compositions
  var fakeIndex = 0; // Index of an item in the array of queued compositions
  for (; fakeIndex < queueArray.length; fakeIndex++) {
    var realIndex = queueArray[fakeIndex]; 
    //Index of the queued Item in the entire render queue (including finished and non-queued items)
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
  // Rendering is done! Switch the panel's display back to normal! 
  document.getElementById("loggedIn").style.display = "block"; 
  document.getElementById("RenderingDiv").style.display = "none"; 
}
```
>Some scripting functions, like `RenderQueueItem.onStatusChanged` wouldn't return until rendering was completed, or would crash/freeze After Effects otherwise. So, I decided to queue and render each item individually in order to better update the online database and maintain reliability.

### **Performance Woes**

I personally thought it was extremely important to make Render Tracker as performant as possible. However, it isn't possible to intercept the native After Effects render button or listen for items being *added* to the queue.[^1] This left me with two options in order to keep the online database updated with the Render Queue: 

[^1]: Technically, this is possible through the use of a plugin and the C++ SDK. However, as mentioned in the first chapter, the `RenderQueueMonitorSuite` needed in order to monitor the Render Queue [hasn't been working in recent versions of After Effects.](https://community.adobe.com/t5/after-effects-discussions/aegp-registerlistener-in-ae-sdk-2017-1/m-p/12046478#M171237))

1. Implement my own render button which executes the function above.
   1. The primary issue with this solution is that starting renders via `app.project.renderQueue.render()` [freezes After Effects](https://adobe-video.uservoice.com/forums/911311-after-effects/suggestions/34795705-after-effects-appears-frozen-when-render-launched) until rendering is finished and produces a crash if the user attempts to further interact with AE.
   2. An ideal solution doesn't require the user going out of it's way to use new functionality.I wanted Render Tracker to be a seamless solution, and adding another button wouldn't be inline with that goal.
  
2. Check the Render Queue on a regular interval and update the database as needed. 
   1. My concern was this wasn't a *performance-concious* approach and wanted to avoid constantly querying the render queue to avoid any performance impact they may have caused.

 I used `performance.now()` to measure the execution time for checking the render queue and ran many different benchmarks and tests in order to determine the kind of impact (if any) they may have had. There was no measurable performance impact and the functions ran in an infinitesimaly small amount of time. After thought and input from frequent After Effects users, I decided it was an acceptable decision to regularly check the queue. However, I kept `renderAndUpdate()` to be used when remotely starting renders. 

 ```js
 async function checkRQChange() {
    const newArray = await runJSX("getRQArray");
    const newProjName = await runJSX("getProjName");
    if (newArray != oldArray || oldProjName != newProjName) {
      await writeUserData();
      oldArray = newArray;
      oldProjName = newProjName;
    }
}
 ```
 > `checkRQChange()` is run on a regular interval to update the database when items are changed or updated in the Render Queue. 

 I'll return to more of the CEP panel's code in the next chapter, but feel free to look through [main.js LINK NEEDED](LINK) if you would like a more complete picture of how the extension works!

### **A Spoonful of HTML and CSS**

With it's uncountable number of built in panels, (and the many extra panels users may have due to plug-ins and other extensions) After Effects already looks wild enough. 

![Screenshot of After Effects](https://user-images.githubusercontent.com/70298555/137464984-b2f610a1-6c39-418e-a14b-2ab6018a4a8d.png)

>My usual After Effects workspace, without a project or composition open. This is as clean as it will ever be!

Because I wanted Render Tracker to be more of a "set-it and forget-it" type of experience, I didn't need a fancy or intricate UI, and I felt like a simple and clean interface would go a long way.

<img width="456" alt="CEP Panel Log-in" src="https://user-images.githubusercontent.com/70298555/137471330-478e6886-fe31-48a8-85d1-3d3cacc9f631.png">

> The panel's log in display. After users log-in, the panel gets out of the way and only displays render and connection status.


I used [Adobe's Spectrum CSS](https://spectrum.adobe.com) in order to make sure my extension was visually seamless with After Effects and Adobe's style and design guidelines.

___
## Chapter 3: Into The Cloud!

The work we've done so far is great and all, but the *whole point* was being able manage the queue and recieve notifications *anywhere*.

Let's figure out how we can get all this data out of After Effects and *into the cloud*! 

### **What is Firebase?**
Firebase is part of Google's cloud development kit. It provides cloud-related tools in the development of iOS, Android, and web apps. I previously mentioned that a CEP Panel was basically a little browser running in After Effects- this means we can use Firebase's web app tools for our extension!

Because Firebase is an extremely prevalent and popular platform with [great documentation](https://firebase.google.com/docs), I'll only be covering topics that are particularly relevant to Render Tracker. I invite you to take a look through the repository [particularly the cloud functions and extension file LINK NEEDED](LINK) if you would like to see the rest of Firebase in action.

### **Realtime Database**

Each user's project and render queue info needs to be uploaded to an online database so that they can retrieve it from the mobile app, and recieve notifications when items have been completed. [Firebase offers two different databases for varying use-cases](https://firebase.google.com/docs/firestore/rtdb-vs-firestore). I decided to use the Realtime database because it was better suited to what Render Tracker needed. 

The Realtime database is stored as a JSON data, and can be visualized as a tree. In our case, one of the branches is `users`, which holds the render queue info for each user under their Render Tracker `uid`.

<img width="456" alt="users JSON Tree" src="https://user-images.githubusercontent.com/70298555/137468499-2c03c6cd-2315-4139-acea-c5eceaca3a32.png">

> The user branch of the JSON tree. Don't worry, the two unique identifiers shown above are my accounts!

> The status codes are directly returned from After Effects. `3019` means the item has successfully finished rendering! `3016` means an item is currently rendering, and `3015` means an item is queued and waiting to be rendered. The rest of the status codes are defined in the [documentation](https://ae-scripting.docsforadobe.dev/renderqueue/renderqueueitem/#renderqueueitem-status) if you would like to take a look at them.


This information is pushed to the database in `writeUserData()`. Feel free to [go back](#cep-functions) and re-read that function!

One of the most useful features of the Realtime database is the ability to "listen" for changes on a branch. This feature is essential to Render Tracker as it powers the iOS UI and allows us to avoid constantly querying the database.

<img width="456" alt="utils JSON Tree" src="https://user-images.githubusercontent.com/70298555/137467356-aad43c53-374b-4e66-af0e-f9f866cd1dfb.png">


> The `utils` branch of the tree contains the "buttons" for each user, as well as the project name and APNS and Firebase cloud messaging notification tokens. 

In order to allow the user to clear the queue and start renders remotely, the iOS app has UI elements which set these database entries to `1`. On the After Effects side, the extension listens to these entries, and runs the relevant functions when they have been updated. After running the relevant functions, the entry is set back to `0`. 

```js 
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
```
> `renderButtonListener()` listens to changes on the relevant leaf and calls `renderAndUpdate()` when the user wants to start a render. 

The other listener used in the After Effects extension is `clearQueueListener()`, which clears the queue and updates the database afterwards. 

### **Push Notifications** 

Because client-side javascript isn't secure, I decided to implement push notifications server-side. This function sends push notifications when items in the Render Queue are finished.

```js
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
// The rest of the function is continued below!
```
> I developed database security rules so that users can't access the database outside of their own `uid` branches. The server-side functions, however, have admin-privledges in order to listen to all branches. 

While more complex, this function works off the same "listening" principal that we used earlier! It listens to changes in `RenderStatus` for every `uid` in the tree, and when any value is updated, it stores that `uid` and `index` for use. 

>Another powerful feature is the ability to use `change.before.val()` and `change.after.val()` in order to compare values directly before and after an update. 

The function compares before and after values for the Render Status, and if the item went from a non-complete status to `3019` (the status for a finished item), it sends a push notification to the user! 

The first step in sending the push notification is grabbing each user's notification token(s) from the database. These are under the `util` branch for each user, and are created and updated when the user logs-in or opens the iOS app. 

We can then create a payload with the `projectName` and `compName` from earlier and send this payload to each notification token! 

```JS
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
```
> Notification tokens are regularly updated by the client, so we make sure to remove any tokens which aren't registered anymore to keep the database clean!

Beyond sending push notifications, there are several other cloud functions which handle important tasks like user authorization and setting custom security claims! Feel free to read the rest of the server-side code [here LINK NEEDED](LINK).


## Chapter 4: Down the iOS Rabbit-Hole

Similiar to Firebase, I won't cover all the intracies of developing for iOS, and will only cover topics that were relevant to Render Tracker specifically! You can [find iOS documentation here](https://developer.apple.com/documentation/), and the iOS developer community is absolutely massive with tons of great resources to learn from and get started! If you would like to view how the full iOS app works, I invite you to take a look at the files [here! LINK NEEDED](LINK)

Before we can start developing a UI, we need to pull our info down from the database.

```swift
class RQItemViewModel: ObservableObject {
    
    @Published var rqItems = [RQItem]()
    
    var uidRef: DatabaseReference = Database.database().reference().ref.child("/users/" + (Auth.auth().currentUser?.uid)! + "/")
    var userHandle: DatabaseHandle?
    
    func startRQItemListener() {
        userHandle = uidRef.observe(.value) { snapshot in
            self.rqItems = []
            let enumator = snapshot.children
            while let rest = enumator.nextObject() as? DataSnapshot {
                let dict = rest.value as? [String : AnyObject] ?? [:]
                let rqtest = RQItem(compName: dict["CompName"] as! String, renderStatus: dict["RenderStatus"] as! String)
                self.rqItems.append(rqtest)
            }
        }
    }
    
    func stopRQItemListener() {
        if userHandle != nil {
            uidRef.removeObserver(withHandle: userHandle!)
        }
    }
}
```

>The `RQItemViewModel`  class is an `ObservableObject`. Whenever an `ObservableObject` is updated or changed, the `View` is automatically refreshed to present the updated information.

 We use a listener to pull info from the database and keep up to data with any changes. The `CompName` and `RenderStatus` pulled from the database are used to create a new `RQItem`, which has it's own `RQItemView`. 

 ```swift
 struct RQItemView: View {
    var index: Int
    var compName: String
    var renderStatus: String
    var body: some View {
        HStack {
            Text(String(index))
                .font(.headline.monospacedDigit())
                .fontWeight(.medium)
                .foregroundColor(Color.gray)
                .padding(.trailing)
            Text(compName)
                .font(.title2.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.leading)
                .padding([.top, .bottom, .trailing])
            Spacer()
            if (renderStatus == "3012") {
                Text("Paused")
                    .foregroundColor(Color.orange)
            }
            // Some more else if statements here - cut for length.
            // ....
            else if (renderStatus == "3015") {
                Text("Queued")
                    .foregroundColor(Color.blue)
            }
            else if (renderStatus == "3016") {
                Text("Rendering")
                    .foregroundColor(Color.purple)
            }
            // ....
            else if (renderStatus == "3019") {
                Text("Done ✓")
                    .foregroundColor(Color.green)
            }
        }
        .font(.title2)
    }
}
```
The `RQItemView` takes the `compName` and `renderStatus` pulled from the database and uses SwiftUI to display each item in `RQListView`.

```JS

struct RQListView: View {
    var rqItems: [RQItem]
    var body: some View {
        if (rqItems.count == 0) { // No items in the Render Queue, display a nice message!
            ZStack{
                Rectangle().foregroundColor(Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255))
                VStack(alignment: .center){
                    Spacer()
                    Text("No Items in the Render Queue.")
                        .font(.body)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(.all)
                    Text("Enjoy the break! You deserve it.")
                        .font(.body)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(.all)
                    Spacer()
                }
            }
        }
        else { // Items in the Render Queue, display them!
            List {
                ForEach(rqItems.indices, id: \.self) { index in
                    RQItemView(index: index + 1, compName: rqItems[index].compName, renderStatus: rqItems[index].renderStatus)
                        .listRowBackground((index  % 2 == 0) ? Color(red: 37 / 255, green: 37 / 255, blue: 37 / 255) : Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255))
                }
            }
        }
    }
}
```
>All the `RQItemViews` are placed into a scrollable list to be viewed by the user. If there are no items in the Render Queue, we instead display a nice message :).

Almost done, we need to implement the Render and Clear Queue buttons!

```swift
struct FooterView: View {
    
    @ObservedObject var projName: RenderQueueManager
    @State private var showingAlert = false
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                projName.startRender()
            }) {
                Text("Render")
                    .fontWeight(.medium)
                    .frame(minWidth: 0, maxWidth: 300, maxHeight: 20)
                    .foregroundColor(Color.white)
                    .padding(.all, 8.0)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
            Button(action: {
                showingAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Queue").lineLimit(1)
                }
                .frame(minWidth: 0, maxWidth: 125, maxHeight: 18.5)
                .foregroundColor(Color.red)
                .padding(.all, 8.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 1.5))
                )
            } .alert(isPresented:$showingAlert) {
                Alert(
                    title: Text("Are you sure you want to clear the Render Queue?"),
                    primaryButton: .destructive(Text("Clear Queue")) {
                        projName.clearQueue()
                    },
                    secondaryButton: .cancel()
                )
            }
            Spacer()
        }
    }
}
```

Each button calls a function to push a `1` to their respective database entries, as discussed in [Realtime Database](#realtime-database). Both buttons were designed to closely follow Adobe design guidelines and style. 

```swift
class RenderQueueManager: ObservableObject {
    @Published var compName = "No Project Open"
    lazy var compRef: DatabaseReference = Database.database().reference().ref.child("/utils/" + (Auth.auth().currentUser?.uid)! + "/ProjectName")
    var compHandle: DatabaseHandle?
    lazy var buttonRef: DatabaseReference = Database.database().reference().ref.child("/utils/" + (Auth.auth().currentUser?.uid)!)
    
    func startProjectNameListener() {
        compHandle = compRef.observe(.value, with: { snapshot in
            if let value = snapshot.value as? String{
                self.compName = value
            }
        })
    }
    
    func stopProjectNameListener() {
        if compHandle != nil {
            compRef.removeObserver(withHandle: compHandle!)
        }
    }
    
    func startRender() {
        buttonRef.updateChildValues(["RenderButton": 1])
    }
    
    func clearQueue() {
        buttonRef.updateChildValues(["ClearButton": 1])
    }
}
```
> `RenderQueueManager` handles everything that's stored in each user's `util` branch.

Last but certainly not least is the project name! Along with our `startRender()` and `clearQueue()` functions, it also lives in `RenderQueueManager`. I'll skip over `HeaderView`, which contains the project name, as it isn't particularly interesting or unique.

 All the views are stacked together into `AfterEffectsView` to create the final display for the app! 

```swift
struct AfterEffectsView: View {
    
    @ObservedObject var sessionStore: SessionStore
    @ObservedObject var projName = RenderQueueManager()
    @ObservedObject var rqItemView = RQItemViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255).ignoresSafeArea()
            VStack {
                HeaderView(projName: projName).padding(.bottom, -1)
                RQListView(rqItems: rqItemView.rqItems)
                FooterView(projName: projName)
                    .padding(.bottom, 6.0)
            }
        }
        .onAppear {
            projName.startProjectNameListener()
            rqItemView.startRQItemListener()
        }.onDisappear {
            projName.stopProjectNameListener()
            rqItemView.stopRQItemListener()
        }
    }
}
```
> The database listeners are started and stopped when the `View` appears and dissapears to make sure the displayed info is up to date, while ensuring listeners are only run when neccessary.

That's it! We've covered most major parts of the project. We began with Adobe ExtendScript to pull relevant information out of After Effects, and then used Adobe's Common Extensibility Platform (CEP) in order to move that data into Firebase's realtime database. From there, we added realtime push notifications, and then developed an iOS app to beautifully represent that data and lets users remotely control their queue!

## Disaster Strikes, Concluding Thoughts

**On June 22 2021, [Adobe announced render queue notifications](https://community.adobe.com/t5/after-effects-beta-discussions/render-queue-notifications-now-available-in-18-4x37/m-p/12133791) as the latest feature available in the After Effects Beta.**

It was very bittersweet. I was genuinely excited that Adobe was finally implementing this feature natively into After Effects. After all, I only decided to develop Render Tracker because I really believed it would be valuable to users like myself. It definitely does sting on occasion though. 

Looking back, the whole process was quite enjoyable and undoubtedly a valuable and irreplacable learning experience. It provided software engineering and development experience which simply can't be taught in class. Besides, now I can share my code here and *hopefully* aid others in their development adventures. Maybe it just provides an interesting read!

While I walked through many of the crucial pieces of this project, I really only covered a small portion of the code I wrote. What I did display was only what ended up being successful, and doesn't represent the wild amount of learning, debugging, testing, reading, *improvement*, and occasional trial and error that got me here. Developing any big project isn't easy, but I believe it's worth it, so don't give up when it gets rough! I hope this project can serve as some form of inspiration for others looking to develop for Adobe applications or whatever else they may feel passionate about. 
