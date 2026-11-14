const fs = require("fs");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  deleteField,
  arrayRemove,
} = require("firebase/firestore");

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "medapp-staging",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync("firestore.rules", "utf8"),
    },
  });
});

afterAll(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, "profiles", "profile1"), {
      ownerUid: "owner123",
      kind: "self",
      name: "Test Patient",
      timezone: "America/New_York",

      roles: {
        owner123: "owner",
        caregiver123: "caregiver",
        viewer123: "viewer",
      },

      memberUids: [
        "owner123",
        "caregiver123",
        "viewer123",
      ],

      healthUids: [
        "owner123",
        "caregiver123",
      ],

      permissions: {
        caregiver123: {
          editMedications: true,
          logDoses: true,
        },
      },
    });

        await setDoc(
      doc(db, "profiles", "profile1", "medications", "med1"),
      {
        name: "Test Medicine",
        strength: "500mg",
        profileId: "profile1",
        status: "active",
        source: "manual",
        schedule: {
          type: "daily",
          times: ["08:00"],
          startDate: new Date(),
          version: 1,
        },
        lowStockDays: 7,
        createdAt: new Date(),
        createdBy: "owner123",
        updatedAt: new Date(),
        updatedBy: "owner123",
      }
    );

    await setDoc(
      doc(db, "profiles", "profile1", "doses", "dose1"),
      {
        medId: "med1",
        status: "pending",
      }
    );
  });
});

describe("Firestore Security Rules — M0", () => {

  test("Unauthenticated users cannot read profiles", async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(
      getDoc(doc(db, "profiles", "profile1"))
    );
  });

  test("Owner can read profile", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertSucceeds(
      getDoc(doc(db, "profiles", "profile1"))
    );
  });

  test("Caregiver can read medications", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      getDoc(doc(db, "profiles", "profile1", "medications", "med1"))
    );
  });

  test("Caregiver with permission can update medication", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      updateDoc(
        doc(db, "profiles", "profile1", "medications", "med1"),
            { name: "Updated Medicine", updatedAt: new Date() }
      )
    );
  });

  test("Viewer cannot update medication", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1", "medications", "med1"),
        { name: "Unauthorized Update" }
      )
    );
  });

  test("Unauthorized user cannot read medication", async () => {
    const db = testEnv.authenticatedContext("stranger123").firestore();

    await assertFails(
      getDoc(doc(db, "profiles", "profile1", "medications", "med1"))
    );
  });

  test("Caregiver can log dose", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      updateDoc(
        doc(db, "profiles", "profile1", "doses", "dose1"),
        { status: "taken" }
      )
    );
  });

  test("Viewer cannot log dose", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1", "doses", "dose1"),
        { status: "taken" }
      )
    );
  });

  test("Caregiver cannot change profile owner", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1"),
        { ownerUid: "caregiver123" }
      )
    );
  });

  test("Owner cannot change ownerUid", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(
        doc(db, "profiles", "profile1"),
        { ownerUid: "anotherUser" }
      )
    );
  });

});
describe("Profile Creation Security — M0", () => {

  test("Authenticated user can create own profile", async () => {
    const db = testEnv.authenticatedContext("newOwner123").firestore();

    await assertSucceeds(
      setDoc(doc(db, "profiles", "newProfile1"), {
        ownerUid: "newOwner123",
        kind: "self",
        name: "Test Patient",
        timezone: "America/New_York",

        roles: {
          newOwner123: "owner",
        },

        memberUids: ["newOwner123"],
        healthUids: ["newOwner123"],
        permissions: {},
      })
    );
  });

  test("User cannot create profile for another owner", async () => {
    const db = testEnv.authenticatedContext("attacker123").firestore();

    await assertFails(
      setDoc(doc(db, "profiles", "newProfile2"), {
        ownerUid: "victim123",
        kind: "self",
        name: "Fake Profile",
        timezone: "America/New_York",

        roles: {
          victim123: "owner",
        },

        memberUids: ["victim123"],
        healthUids: ["victim123"],
        permissions: {},
      })
    );
  });

  test("User cannot assign caregiver during profile creation", async () => {
    const db = testEnv.authenticatedContext("newOwner123").firestore();

    await assertFails(
      setDoc(doc(db, "profiles", "newProfile3"), {
        ownerUid: "newOwner123",
        kind: "self",
        name: "Test Patient",
        timezone: "America/New_York",

        roles: {
          newOwner123: "owner",
          attacker123: "caregiver",
        },

        memberUids: [
          "newOwner123",
          "attacker123",
        ],

        healthUids: ["newOwner123"],

        permissions: {
          attacker123: {
            editMedications: true,
          },
        },
      })
    );
  });

  test("User cannot create profile without owner role", async () => {
    const db = testEnv.authenticatedContext("newOwner123").firestore();

    await assertFails(
      setDoc(doc(db, "profiles", "newProfile4"), {
        ownerUid: "newOwner123",
        kind: "self",
        name: "Test Patient",
        timezone: "America/New_York",

        roles: {
          newOwner123: "viewer",
        },

        memberUids: ["newOwner123"],
        healthUids: ["newOwner123"],
        permissions: {},
      })
    );
  });

});
describe("Role Escalation & Health Access — M0", () => {

  test("Caregiver cannot promote themselves to owner", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "roles.caregiver123": "owner",
      })
    );
  });

  test("Viewer cannot promote themselves to caregiver", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "roles.viewer123": "caregiver",
      })
    );
  });

  test("Caregiver cannot grant themselves health access", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        healthUids: [
          "owner123",
          "caregiver123",
          "attacker123",
        ],
      })
    );
  });

  test("Viewer cannot change permissions", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "permissions.viewer123.editMedications": true,
      })
    );
  });

  test("Authorized caregiver can read health records", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();

    await assertSucceeds(
      getDoc(
        doc(db, "profiles", "profile1", "allergies", "allergy1")
      )
    );
  });

    test("Viewer without health access cannot read health records", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    // M3: Allergies are now readable by all members (canRead)
    // Use vitals instead — still requires health access (canViewHealth)
    await assertFails(
      getDoc(
        doc(db, "profiles", "profile1", "vitals", "vital1")
      )
    );
  });

  // M3: Any member can read allergies (new behavior)
  test("Viewer can read allergies (M3 — any member can read)", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();

    await assertSucceeds(
      getDoc(
        doc(db, "profiles", "profile1", "allergies", "allergy1")
      )
    );
  });

});

describe("Owner Profile Update Security — M0", () => {

  test("Owner can update profile name", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertSucceeds(
      updateDoc(doc(db, "profiles", "profile1"), {
        name: "Updated Patient Name",
      })
    );
  });

  test("Owner cannot modify roles directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "roles.viewer123": "caregiver",
      })
    );
  });

  test("Owner cannot modify memberUids directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        memberUids: ["owner123", "attacker123"],
      })
    );
  });

  test("Owner cannot modify healthUids directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        healthUids: ["owner123", "attacker123"],
      })
    );
  });

  test("Owner cannot grant medication permission directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();

    await assertFails(
      updateDoc(doc(db, "profiles", "profile1"), {
        "permissions.viewer123.editMedications": true,
      })
    );
  });

});

describe("Customers (Subscriptions) Security — M12", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "customers", "owner123"), {
        activePlan: "annual_premium",
        status: "active",
      });
    });
  });

  test("User can read their own customer record", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(getDoc(doc(db, "customers", "owner123")));
  });

  test("User cannot read another user's customer record", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(getDoc(doc(db, "customers", "owner123")));
  });

  test("User cannot write their own customer record", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "customers", "owner123"), { activePlan: "family_plan" })
    );
    await assertFails(
      setDoc(doc(db, "customers", "owner123"), { activePlan: "family_plan" })
    );
  });

  test("Unauthenticated user cannot read customer records", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, "customers", "owner123")));
  });

});


describe("Users legal acceptance — M13 step 2", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "users", "owner123"), {
        email: "o@example.com",
        displayName: "Owner",
        legal: { termsVersion: "1.0", privacyVersion: "1.0" },
        legalVersions: { terms: "1.0", privacy: "1.0" },
      });
      await setDoc(doc(db, "users", "viewer123"), {
        email: "v@example.com",
        displayName: "Viewer",
      });
    });
  });

  test("User can record acceptance of newer legal versions", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), {
        legal: { termsVersion: "1.1", privacyVersion: "1.1", acceptedAt: new Date() },
        legalVersions: { terms: "1.1", privacy: "1.1" },
        updatedAt: new Date(),
      })
    );
  });

  test("User cannot record acceptance for another user", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "viewer123"), {
        legal: { termsVersion: "9.9", privacyVersion: "9.9" },
        updatedAt: new Date(),
      })
    );
  });

  test("Legal acceptance update cannot smuggle in protected fields", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        legal: { termsVersion: "1.1", privacyVersion: "1.1" },
        plan: "family_plan",
        updatedAt: new Date(),
      })
    );
  });

});


describe("Users settings map — M13 step 3", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users", "owner123"), {
        email: "o@example.com",
        displayName: "Owner",
        settings: { doseEnabled: false, escalationMinutes: 25 },
      });
    });
  });

  test("Saving language by dotted path keeps notification settings", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), {
        "settings.language": "hi",
        "settings.textSizeIndex": 3,
      })
    );
    const snap = await assertSucceeds(getDoc(doc(db, "users", "owner123")));
    expect(snap.data().settings).toEqual({
      doseEnabled: false,
      escalationMinutes: 25,
      language: "hi",
      textSizeIndex: 3,
    });
  });

  test("Saving notification keys by dotted path keeps language", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), { "settings.language": "es" })
    );
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), { "settings.doseEnabled": true })
    );
    const snap = await assertSucceeds(getDoc(doc(db, "users", "owner123")));
    expect(snap.data().settings.language).toBe("es");
    expect(snap.data().settings.doseEnabled).toBe(true);
  });

  test("User cannot change another user's settings", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), { "settings.language": "ar" })
    );
  });

});


describe("Config (remote FAQ) — M13 step 4", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "config", "faq"), {
        items: [{ id: "a", order: 1, q: { en: "Q?" }, a: { en: "A." } }],
      });
    });
  });

  test("Signed-in user can read config/faq", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(getDoc(doc(db, "config", "faq")));
  });

  test("Unauthenticated user cannot read config/faq", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, "config", "faq")));
  });

  test("Clients cannot write config/faq", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      setDoc(doc(db, "config", "faq"), { items: [] })
    );
    await assertFails(
      updateDoc(doc(db, "config", "faq"), { items: [] })
    );
    await assertFails(deleteDoc(doc(db, "config", "faq")));
  });

});


describe("Support tickets — M13 step 5", () => {

  const { serverTimestamp, collection, addDoc } = require("firebase/firestore");

  const ticket = (over = {}) => ({
    uid: "owner123",
    subject: "Reminders are not ringing",
    body: "Since yesterday no dose reminder rings on my phone.",
    appVersion: "1.0.0",
    device: "android Android 15",
    locale: "en",
    status: "open",
    createdAt: serverTimestamp(),
    ...over,
  });

  test("User can create their own ticket", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(addDoc(collection(db, "supportTickets"), ticket()));
  });

  test("Unauthenticated user cannot create a ticket", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(addDoc(collection(db, "supportTickets"), ticket()));
  });

  test("Cannot create a ticket for another user", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ uid: "viewer123" }))
    );
  });

  test("Extra or missing fields are rejected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ admin: true }))
    );
    const { body, ...withoutBody } = ticket();
    await assertFails(addDoc(collection(db, "supportTickets"), withoutBody));
  });

  test("Empty or oversized subject/body are rejected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ subject: "" }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ subject: "x".repeat(121) }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ body: "" }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ body: "x".repeat(2001) }))
    );
  });

  test("Limits are inclusive (120 / 2000 characters)", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      addDoc(
        collection(db, "supportTickets"),
        ticket({ subject: "x".repeat(120), body: "y".repeat(2000) })
      )
    );
  });

  test("Status must be open and createdAt must be server time", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ status: "closed" }))
    );
    await assertFails(
      addDoc(collection(db, "supportTickets"), ticket({ createdAt: new Date(2020, 1, 1) }))
    );
  });

  test("User reads own tickets only; tickets are immutable", async () => {
    let id;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const r = await addDoc(collection(context.firestore(), "supportTickets"), {
        ...ticket(),
        createdAt: new Date(),
      });
      id = r.id;
    });
    const owner = testEnv.authenticatedContext("owner123").firestore();
    const other = testEnv.authenticatedContext("viewer123").firestore();
    await assertSucceeds(getDoc(doc(owner, "supportTickets", id)));
    await assertFails(getDoc(doc(other, "supportTickets", id)));
    await assertFails(updateDoc(doc(owner, "supportTickets", id), { subject: "x" }));
    await assertFails(deleteDoc(doc(owner, "supportTickets", id)));
  });

});


describe("Account deletion request — M14 step 4", () => {

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "users", "owner123"), {
        email: "o@example.com",
        displayName: "Owner",
      });
      await setDoc(doc(db, "users", "pending123"), {
        email: "p@example.com",
        displayName: "Pending",
        deletionRequestedAt: new Date("2026-11-01T00:00:00Z"),
      });
    });
  });

  test("User can request deletion with the server time", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      })
    );
  });

  test("Request with a client-chosen time is rejected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: new Date("2020-01-01T00:00:00Z"),
      })
    );
  });

  test("User can cancel a pending request", async () => {
    const db = testEnv.authenticatedContext("pending123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: deleteField(),
        updatedAt: serverTimestamp(),
      })
    );
    const snap = await assertSucceeds(
      getDoc(doc(testEnv.authenticatedContext("pending123").firestore(), "users", "pending123"))
    );
    expect(snap.data().deletionRequestedAt).toBeUndefined();
  });

  test("Cannot move a pending request to a different time", async () => {
    const db = testEnv.authenticatedContext("pending123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: new Date("2030-01-01T00:00:00Z"),
      })
    );
  });

  test("Cannot request deletion for another user", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: deleteField(),
      })
    );
    await assertFails(
      updateDoc(doc(db, "users", "pending123"), {
        deletionRequestedAt: serverTimestamp(),
      })
    );
  });

  test("Deletion request cannot smuggle in other fields", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
        plan: "family_plan",
      })
    );
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
        displayName: "Changed",
      })
    );
  });

  test("Unauthenticated user cannot request deletion", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: serverTimestamp(),
      })
    );
  });

  test("User document still cannot be deleted directly", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(deleteDoc(doc(db, "users", "owner123")));
  });

});


// ---------------------------------------------------------------
// M14 step 5 — account purge (delete allowed only after the grace period)
// ---------------------------------------------------------------

const DAY = 24 * 60 * 60 * 1000;

async function seedPurgeData(requestedAt, uid = "owner123") {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const user = { email: "x@example.com", displayName: "X" };
    if (requestedAt) user.deletionRequestedAt = requestedAt;
    await setDoc(doc(db, "users", uid), user);
    await setDoc(doc(db, "users", uid, "devices", "dev1"), { token: "t" });

    const p = ["profiles", "profile1"];
    await setDoc(doc(db, ...p, "medications", "med1", "inventoryEvents", "ev1"), { delta: -1 });
    await setDoc(doc(db, ...p, "doses", "dose2"), { medId: "med1", status: "taken" });
    await setDoc(doc(db, ...p, "pharmacies", "ph1"), { name: "Ph" });
    await setDoc(doc(db, ...p, "dailySummaries", "2026-11-01"), { taken: 1 });
    await setDoc(doc(db, ...p, "vitals", "v1"), { bp: "120/80" });
    await setDoc(doc(db, ...p, "symptoms", "s1"), { name: "x" });
    await setDoc(doc(db, ...p, "allergies", "a1"), { name: "Pen" });
  });
}

describe("Account purge after grace period — M14 step 5", () => {

  beforeEach(async () => {
    await seedPurgeData(new Date(Date.now() - 8 * DAY));
  });

  test("Owner can delete every kind of record once the grace period is over", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    const p = ["profiles", "profile1"];

    await assertSucceeds(deleteDoc(doc(db, ...p, "medications", "med1", "inventoryEvents", "ev1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "medications", "med1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "doses", "dose1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "doses", "dose2"))); // taken dose
    await assertSucceeds(deleteDoc(doc(db, ...p, "pharmacies", "ph1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "dailySummaries", "2026-11-01")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "vitals", "v1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "symptoms", "s1")));
    await assertSucceeds(deleteDoc(doc(db, ...p, "allergies", "a1")));
  });

  test("Owner can delete the profile, devices and the user document", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(deleteDoc(doc(db, "profiles", "profile1")));
    await assertSucceeds(deleteDoc(doc(db, "users", "owner123", "devices", "dev1")));
    await assertSucceeds(deleteDoc(doc(db, "users", "owner123")));
  });

  test("Deleting a profile does not need its children to be empty first", async () => {
    // Firestore does not cascade; the app deletes children first. The rule
    // itself must still allow the owner to remove the profile document.
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(deleteDoc(doc(db, "profiles", "profile1")));
  });

  test("A caregiver cannot purge the owner's data even with their own due request", async () => {
    await seedPurgeData(new Date(Date.now() - 8 * DAY), "caregiver123");
    const db = testEnv.authenticatedContext("caregiver123").firestore();
    await assertFails(deleteDoc(doc(db, "profiles", "profile1")));
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "medications", "med1")));
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "doses", "dose2")));
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "vitals", "v1")));
  });

  test("Cannot delete another user's document", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(deleteDoc(doc(db, "users", "viewer123")));
  });

  test("Records that are not health data stay protected", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "profiles", "profile1", "randomStuff", "r1"), { a: 1 });
    });
    await assertFails(deleteDoc(doc(db, "profiles", "profile1", "randomStuff", "r1")));
  });

  test("Unauthenticated users cannot purge", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(deleteDoc(doc(db, "profiles", "profile1")));
    await assertFails(deleteDoc(doc(db, "users", "owner123")));
  });
});

describe("Purge is blocked during the grace period — M14 step 5", () => {

  async function expectAllDeletesDenied() {
    const db = testEnv.authenticatedContext("owner123").firestore();
    const p = ["profiles", "profile1"];
    await assertFails(deleteDoc(doc(db, ...p, "medications", "med1", "inventoryEvents", "ev1")));
    await assertFails(deleteDoc(doc(db, ...p, "medications", "med1")));
    await assertFails(deleteDoc(doc(db, ...p, "doses", "dose2"))); // taken
    await assertFails(deleteDoc(doc(db, ...p, "pharmacies", "ph1")));
    await assertFails(deleteDoc(doc(db, ...p, "dailySummaries", "2026-11-01")));
    // vitals / symptoms: the owner may delete single entries at any time
    // (M15), and so may doctors, appointments and notes (M16), so none of
    // them are part of "blocked during the grace period".
    await assertFails(deleteDoc(doc(db, "profiles", "profile1")));
    await assertFails(deleteDoc(doc(db, "users", "owner123")));
  }

  test("2 days after the request: nothing can be deleted", async () => {
    await seedPurgeData(new Date(Date.now() - 2 * DAY));
    await expectAllDeletesDenied();
  });

  test("6 days 23 hours after the request: still blocked", async () => {
    await seedPurgeData(new Date(Date.now() - (7 * DAY - 60 * 60 * 1000)));
    await expectAllDeletesDenied();
  });

  test("No deletion request at all: nothing can be deleted", async () => {
    await seedPurgeData(null);
    await expectAllDeletesDenied();
  });

  test("After cancelling (field removed) deletes are blocked again", async () => {
    await seedPurgeData(new Date(Date.now() - 8 * DAY));
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", "owner123"), { deletionRequestedAt: deleteField() })
    );
    await expectAllDeletesDenied();
  });

  test("User cannot backdate the request to skip the grace period", async () => {
    await seedPurgeData(new Date(Date.now() - 1 * DAY));
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(doc(db, "users", "owner123"), {
        deletionRequestedAt: new Date(Date.now() - 30 * DAY),
      })
    );
    await expectAllDeletesDenied();
  });
});


describe("Member leaves a profile (own access only) — M14 step 6", () => {

  const ref = (db) => doc(db, "profiles", "profile1");

  test("A viewer can remove only their own access", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertSucceeds(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123"),
        healthUids: arrayRemove("viewer123"), // not in the list: no-op
        "roles.viewer123": deleteField(),
        updatedAt: serverTimestamp(),
      })
    );
  });

  test("A caregiver with permissions can leave, entry included", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();
    await assertSucceeds(
      updateDoc(ref(db), {
        memberUids: arrayRemove("caregiver123"),
        healthUids: arrayRemove("caregiver123"),
        "roles.caregiver123": deleteField(),
        "permissions.caregiver123": deleteField(),
      })
    );
  });

  test("Leaving but keeping the permissions entry is rejected", async () => {
    const db = testEnv.authenticatedContext("caregiver123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("caregiver123"),
        healthUids: arrayRemove("caregiver123"),
        "roles.caregiver123": deleteField(),
      })
    );
  });

  test("Leaving but keeping the role entry is rejected", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), { memberUids: arrayRemove("viewer123") })
    );
  });

  test("Cannot remove somebody else's access", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("caregiver123"),
        "roles.caregiver123": deleteField(),
      })
    );
  });

  test("Cannot remove the owner", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("owner123"),
        healthUids: arrayRemove("owner123"),
        "roles.owner123": deleteField(),
      })
    );
  });

  test("Cannot leave AND remove someone else in the same write", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123", "caregiver123"),
        "roles.viewer123": deleteField(),
      })
    );
  });

  test("Cannot promote yourself or change other fields while leaving", async () => {
    const db = testEnv.authenticatedContext("viewer123").firestore();
    await assertFails(updateDoc(ref(db), { "roles.viewer123": "owner" }));
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123"),
        "roles.viewer123": deleteField(),
        name: "Hijacked",
      })
    );
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("viewer123"),
        "roles.viewer123": deleteField(),
        ownerUid: "viewer123",
      })
    );
  });

  test("The owner cannot use the leave path", async () => {
    const db = testEnv.authenticatedContext("owner123").firestore();
    await assertFails(
      updateDoc(ref(db), {
        memberUids: arrayRemove("owner123"),
        healthUids: arrayRemove("owner123"),
        "roles.owner123": deleteField(),
      })
    );
  });

  test("Non-members and anonymous users cannot touch membership", async () => {
    const outsider = testEnv.authenticatedContext("stranger999").firestore();
    await assertFails(
      updateDoc(ref(outsider), { memberUids: arrayRemove("viewer123") })
    );
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      updateDoc(ref(anon), { memberUids: arrayRemove("viewer123") })
    );
  });
});


// ---------------------------------------------------------------
// M15 step 2 — vitals, symptoms and daily summaries
// ---------------------------------------------------------------

describe("Vitals / symptoms rules — M15 step 2", () => {

  // profile1: owner123 (owner), caregiver123 (caregiver, health access),
  //           viewer123 (viewer, NO health access)
  // profileHV: hv123 is a viewer WITH health access (read-only)
  const ownerDb = () => testEnv.authenticatedContext("owner123").firestore();
  const cgDb = () => testEnv.authenticatedContext("caregiver123").firestore();
  const viewerDb = () => testEnv.authenticatedContext("viewer123").firestore();
  const hvDb = () => testEnv.authenticatedContext("hv123").firestore();
  const strangerDb = () => testEnv.authenticatedContext("stranger999").firestore();
  const anonDb = () => testEnv.unauthenticatedContext().firestore();

  const vit = (db, id, pid = "profile1") => doc(db, "profiles", pid, "vitals", id);
  const sym = (db, id, pid = "profile1") => doc(db, "profiles", pid, "symptoms", id);
  const day = (db, id, pid = "profile1") => doc(db, "profiles", pid, "vitalsDaily", id);

  const bp = (uid = "owner123", extra = {}) => ({
    type: "bloodPressure", value: 120, value2: 80, unit: "mmHg",
    measuredAt: new Date(), source: "manual",
    createdBy: uid, createdAt: serverTimestamp(), ...extra,
  });
  const single = (type, value, unit, uid = "owner123", extra = {}) => ({
    type, value, unit, measuredAt: new Date(), source: "manual",
    createdBy: uid, createdAt: serverTimestamp(), ...extra,
  });
  const symptom = (uid = "owner123", extra = {}) => ({
    symptom: "Nausea", severity: 3, occurredAt: new Date(),
    createdBy: uid, createdAt: serverTimestamp(), ...extra,
  });
  const daily = (extra = {}) => ({
    type: "glucose", day: "2026-11-14", count: 3, avg: 100, min: 90, max: 110,
    updatedAt: serverTimestamp(), ...extra,
  });

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "profiles", "profileHV"), {
        ownerUid: "owner123", kind: "self", name: "HV", timezone: "UTC",
        roles: { owner123: "owner", hv123: "viewer" },
        memberUids: ["owner123", "hv123"],
        healthUids: ["owner123", "hv123"],
        permissions: {},
      });
      await setDoc(vit(db, "ownerEntry"), { ...bp("owner123"), createdAt: new Date() });
      await setDoc(vit(db, "cgEntry"), {
        ...single("glucose", 100, "mg/dL", "caregiver123"), createdAt: new Date(),
      });
      await setDoc(sym(db, "ownerSym"), { ...symptom("owner123"), createdAt: new Date() });
      await setDoc(sym(db, "cgSym"), { ...symptom("caregiver123"), createdAt: new Date() });
      await setDoc(day(db, "glucose_2026-11-13"), { ...daily({ day: "2026-11-13" }), updatedAt: new Date() });
      await setDoc(vit(db, "hvEntry", "profileHV"), { ...bp("owner123"), createdAt: new Date() });
    });
  });

  // ---------------- who can write ----------------

  test("Owner and caregiver can create vitals", async () => {
    await assertSucceeds(setDoc(vit(ownerDb(), "n1"), bp("owner123")));
    await assertSucceeds(setDoc(vit(cgDb(), "n2"), single("glucose", 95, "mg/dL", "caregiver123")));
    await assertSucceeds(setDoc(vit(ownerDb(), "n3"), single("weight", 72.4, "kg")));
    await assertSucceeds(setDoc(vit(ownerDb(), "n4"), single("heartRate", 74, "bpm")));
    await assertSucceeds(setDoc(vit(ownerDb(), "n5"), bp("owner123", { pulse: 72, note: "after walk" })));
  });

  test("Viewers, strangers and anonymous users cannot create vitals", async () => {
    await assertFails(setDoc(vit(viewerDb(), "x1"), bp("viewer123")));
    await assertFails(setDoc(vit(hvDb(), "x2", "profileHV"), bp("hv123"))); // health access but read-only
    await assertFails(setDoc(vit(strangerDb(), "x3"), bp("stranger999")));
    await assertFails(setDoc(vit(anonDb(), "x4"), bp("owner123")));
  });

  test("Health readers can still read; viewers without health access cannot", async () => {
    await assertSucceeds(getDoc(vit(ownerDb(), "ownerEntry")));
    await assertSucceeds(getDoc(vit(cgDb(), "ownerEntry")));
    await assertSucceeds(getDoc(vit(hvDb(), "hvEntry", "profileHV")));
    await assertFails(getDoc(vit(viewerDb(), "ownerEntry")));
    await assertFails(getDoc(vit(strangerDb(), "ownerEntry")));
  });

  // ---------------- value rules ----------------

  test("Impossible blood pressure values are rejected", async () => {
    await assertFails(setDoc(vit(ownerDb(), "a"), bp("owner123", { value: 500 })));
    await assertFails(setDoc(vit(ownerDb(), "b"), bp("owner123", { value: 39 })));
    await assertFails(setDoc(vit(ownerDb(), "c"), bp("owner123", { value2: 10 })));
    await assertFails(setDoc(vit(ownerDb(), "d"), bp("owner123", { value2: 80, value: 80 }))); // not lower
    await assertFails(setDoc(vit(ownerDb(), "e"), bp("owner123", { value2: 90, value: 80 })));
    await assertFails(setDoc(vit(ownerDb(), "f"), bp("owner123", { pulse: 5 })));
  });

  test("Blood pressure limits are inclusive", async () => {
    await assertSucceeds(setDoc(vit(ownerDb(), "lo"), bp("owner123", { value: 40, value2: 30 })));
    await assertSucceeds(setDoc(vit(ownerDb(), "hi"), bp("owner123", { value: 300, value2: 200 })));
  });

  test("Blood pressure needs a diastolic value", async () => {
    const d = bp("owner123");
    delete d.value2;
    await assertFails(setDoc(vit(ownerDb(), "nod"), d));
  });

  test("Glucose, weight and heart rate limits", async () => {
    await assertSucceeds(setDoc(vit(ownerDb(), "g1"), single("glucose", 10, "mg/dL")));
    await assertSucceeds(setDoc(vit(ownerDb(), "g2"), single("glucose", 1000, "mg/dL")));
    await assertFails(setDoc(vit(ownerDb(), "g3"), single("glucose", 9, "mg/dL")));
    await assertFails(setDoc(vit(ownerDb(), "g4"), single("glucose", 1001, "mg/dL")));
    await assertFails(setDoc(vit(ownerDb(), "w1"), single("weight", 0, "kg")));
    await assertFails(setDoc(vit(ownerDb(), "w2"), single("weight", 701, "kg")));
    await assertSucceeds(setDoc(vit(ownerDb(), "w3"), single("weight", 700, "kg")));
    await assertFails(setDoc(vit(ownerDb(), "h1"), single("heartRate", 19, "bpm")));
    await assertFails(setDoc(vit(ownerDb(), "h2"), single("heartRate", 301, "bpm")));
  });

  test("Wrong unit, unknown type and non-numbers are rejected", async () => {
    await assertFails(setDoc(vit(ownerDb(), "u1"), single("glucose", 5.5, "mmol/L")));
    await assertFails(setDoc(vit(ownerDb(), "u2"), single("weight", 150, "lb")));
    await assertFails(setDoc(vit(ownerDb(), "u3"), single("oxygen", 98, "%")));
    await assertFails(setDoc(vit(ownerDb(), "u4"), single("weight", "70", "kg")));
  });

  test("Only blood pressure may carry value2 or pulse", async () => {
    await assertFails(setDoc(vit(ownerDb(), "s1"), single("glucose", 95, "mg/dL", "owner123", { value2: 5 })));
    await assertFails(setDoc(vit(ownerDb(), "s2"), single("weight", 70, "kg", "owner123", { pulse: 70 })));
  });

  // ---------------- shape / identity rules ----------------

  test("Unknown fields and missing required fields are rejected", async () => {
    await assertFails(setDoc(vit(ownerDb(), "e1"), bp("owner123", { plan: "pro" })));
    const d = bp("owner123");
    delete d.measuredAt;
    await assertFails(setDoc(vit(ownerDb(), "e2"), d));
  });

  test("createdBy must be the writer and createdAt the server time", async () => {
    await assertFails(setDoc(vit(cgDb(), "i1"), bp("owner123")));
    await assertFails(setDoc(vit(ownerDb(), "i2"), bp("owner123", { createdAt: new Date("2020-01-01") })));
  });

  test("Readings from the future are rejected, small clock skew is fine", async () => {
    await assertFails(setDoc(vit(ownerDb(), "t1"), bp("owner123", { measuredAt: new Date(Date.now() + 3600 * 1000) })));
    await assertSucceeds(setDoc(vit(ownerDb(), "t2"), bp("owner123", { measuredAt: new Date(Date.now() + 2 * 60 * 1000) })));
    await assertSucceeds(setDoc(vit(ownerDb(), "t3"), bp("owner123", { measuredAt: new Date("2020-05-05") })));
  });

  test("Notes are limited to 500 characters", async () => {
    await assertSucceeds(setDoc(vit(ownerDb(), "nt1"), bp("owner123", { note: "n".repeat(500) })));
    await assertFails(setDoc(vit(ownerDb(), "nt2"), bp("owner123", { note: "n".repeat(501) })));
  });

  // ---------------- manual vs synced ids ----------------

  test("Synced readings need externalId and the {source}_{externalId} id", async () => {
    const hk = bp("owner123", { source: "healthkit", externalId: "ABC-1" });
    await assertSucceeds(setDoc(vit(ownerDb(), "healthkit_ABC-1"), hk));
    const hc = bp("owner123", { source: "health_connect", externalId: "rec9" });
    await assertSucceeds(setDoc(vit(ownerDb(), "health_connect_rec9"), hc));

    await assertFails(setDoc(vit(ownerDb(), "randomid"), hk)); // id does not match source
    await assertFails(setDoc(vit(ownerDb(), "health_connect_ABC-1"), hk)); // wrong source prefix
    const noExt = bp("owner123", { source: "healthkit" });
    await assertFails(setDoc(vit(ownerDb(), "healthkit_x"), noExt));
    await assertFails(setDoc(vit(ownerDb(), "healthkit_x"), bp("owner123", { source: "healthkit", externalId: "" })));
  });

  test("Re-syncing the same reading cannot overwrite or duplicate it", async () => {
    const hk = bp("owner123", { source: "healthkit", externalId: "ABC-1" });
    await assertSucceeds(setDoc(vit(ownerDb(), "healthkit_ABC-1"), hk));
    // second write of the same id is an update of a recorded reading -> denied
    await assertFails(setDoc(vit(ownerDb(), "healthkit_ABC-1"), { ...hk, value: 130 }));
  });

  test("Manual readings cannot have an externalId or a synced-looking id", async () => {
    await assertFails(setDoc(vit(ownerDb(), "m1"), bp("owner123", { externalId: "x" })));
    await assertFails(setDoc(vit(ownerDb(), "healthkit_fake"), bp("owner123")));
    await assertFails(setDoc(vit(ownerDb(), "health_connect_fake"), bp("owner123")));
    await assertFails(setDoc(vit(ownerDb(), "z1"), bp("owner123", { source: "fitbit" })));
  });

  // ---------------- update / delete ----------------

  test("Only the note of a reading can be edited", async () => {
    await assertSucceeds(updateDoc(vit(ownerDb(), "ownerEntry"), { note: "felt dizzy" }));
    await assertFails(updateDoc(vit(ownerDb(), "ownerEntry"), { value: 110 }));
    await assertFails(updateDoc(vit(ownerDb(), "ownerEntry"), { measuredAt: new Date("2020-01-01") }));
    await assertFails(updateDoc(vit(ownerDb(), "ownerEntry"), { note: "x", createdBy: "caregiver123" }));
  });

  test("Creator and owner can edit/delete an entry; other caregivers cannot", async () => {
    await assertSucceeds(updateDoc(vit(cgDb(), "cgEntry"), { note: "mine" }));   // creator
    await assertSucceeds(updateDoc(vit(ownerDb(), "cgEntry"), { note: "owner" })); // owner
    await assertFails(updateDoc(vit(cgDb(), "ownerEntry"), { note: "not mine" }));
    await assertFails(deleteDoc(vit(cgDb(), "ownerEntry")));
    await assertSucceeds(deleteDoc(vit(cgDb(), "cgEntry")));
    await assertSucceeds(deleteDoc(vit(ownerDb(), "ownerEntry")));
  });

  test("Viewers cannot edit or delete readings", async () => {
    await assertFails(updateDoc(vit(hvDb(), "hvEntry", "profileHV"), { note: "x" }));
    await assertFails(deleteDoc(vit(hvDb(), "hvEntry", "profileHV")));
    await assertFails(deleteDoc(vit(viewerDb(), "ownerEntry")));
    await assertFails(deleteDoc(vit(strangerDb(), "ownerEntry")));
  });

  // ---------------- symptoms ----------------

  test("Owner and caregiver can log symptoms; viewers cannot", async () => {
    await assertSucceeds(setDoc(sym(ownerDb(), "s1"), symptom("owner123")));
    await assertSucceeds(setDoc(sym(cgDb(), "s2"), symptom("caregiver123", { notes: "after lunch" })));
    await assertFails(setDoc(sym(hvDb(), "s3", "profileHV"), symptom("hv123")));
    await assertFails(setDoc(sym(viewerDb(), "s4"), symptom("viewer123")));
    await assertFails(setDoc(sym(anonDb(), "s5"), symptom("owner123")));
  });

  test("A symptom can link to an existing medication only", async () => {
    await assertSucceeds(setDoc(sym(ownerDb(), "l1"), symptom("owner123", { medicationId: "med1" })));
    await assertFails(setDoc(sym(ownerDb(), "l2"), symptom("owner123", { medicationId: "doesNotExist" })));
    await assertFails(setDoc(sym(ownerDb(), "l3"), symptom("owner123", { medicationId: "" })));
  });

  test("Symptom severity, name, notes and time are validated", async () => {
    await assertFails(setDoc(sym(ownerDb(), "v1"), symptom("owner123", { severity: 0 })));
    await assertFails(setDoc(sym(ownerDb(), "v2"), symptom("owner123", { severity: 6 })));
    await assertFails(setDoc(sym(ownerDb(), "v3"), symptom("owner123", { severity: 3.5 })));
    await assertSucceeds(setDoc(sym(ownerDb(), "v4"), symptom("owner123", { severity: 1 })));
    await assertSucceeds(setDoc(sym(ownerDb(), "v5"), symptom("owner123", { severity: 5 })));
    await assertFails(setDoc(sym(ownerDb(), "n1"), symptom("owner123", { symptom: "" })));
    await assertFails(setDoc(sym(ownerDb(), "n2"), symptom("owner123", { symptom: "a".repeat(101) })));
    await assertSucceeds(setDoc(sym(ownerDb(), "n3"), symptom("owner123", { symptom: "a".repeat(100) })));
    await assertFails(setDoc(sym(ownerDb(), "o1"), symptom("owner123", { notes: "n".repeat(501) })));
    await assertFails(setDoc(sym(ownerDb(), "t1"), symptom("owner123", { occurredAt: new Date(Date.now() + 3600 * 1000) })));
    await assertFails(setDoc(sym(ownerDb(), "x1"), symptom("owner123", { extra: 1 })));
    await assertFails(setDoc(sym(cgDb(), "x2"), symptom("owner123"))); // createdBy mismatch
  });

  test("Symptom: only notes editable; creator or owner may delete", async () => {
    await assertSucceeds(updateDoc(sym(cgDb(), "cgSym"), { notes: "updated" }));
    await assertFails(updateDoc(sym(cgDb(), "cgSym"), { severity: 1 }));
    await assertFails(updateDoc(sym(cgDb(), "ownerSym"), { notes: "no" }));
    await assertFails(deleteDoc(sym(cgDb(), "ownerSym")));
    await assertSucceeds(deleteDoc(sym(cgDb(), "cgSym")));
    await assertSucceeds(deleteDoc(sym(ownerDb(), "ownerSym")));
  });

  // ---------------- vitalsDaily ----------------

  test("Owner and caregiver can write a valid daily summary (and overwrite it)", async () => {
    await assertSucceeds(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily()));
    await assertSucceeds(setDoc(day(cgDb(), "glucose_2026-11-14"), daily({ count: 4 })));
    await assertSucceeds(setDoc(day(ownerDb(), "bloodPressure_2026-11-14"), daily({
      type: "bloodPressure", avg: 125, min: 120, max: 130, avg2: 82, min2: 80, max2: 85,
    })));
  });

  test("Daily summary id must be {type}_{day} and values must be consistent", async () => {
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-15"), daily())); // id/day mismatch
    await assertFails(setDoc(day(ownerDb(), "x"), daily()));
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily({ avg: 500 }))); // avg above max
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily({ min: 120, max: 100 })));
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily({ min: 5 }))); // below glucose limit
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily({ count: 0 })));
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily({ avg2: 80, min2: 70, max2: 90 }))); // glucose has no second value
    await assertFails(setDoc(day(ownerDb(), "bloodPressure_2026-11-14"), daily({
      type: "bloodPressure", avg: 125, min: 120, max: 130,
    }))); // BP needs the second value
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily({ updatedAt: new Date("2020-01-01") })));
    await assertFails(setDoc(day(ownerDb(), "glucose_2026-11-14"), daily({ type: "oxygen" })));
  });

  test("Viewers and strangers cannot write or delete daily summaries", async () => {
    await assertFails(setDoc(day(hvDb(), "glucose_2026-11-14", "profileHV"), daily()));
    await assertFails(setDoc(day(viewerDb(), "glucose_2026-11-14"), daily()));
    await assertFails(setDoc(day(strangerDb(), "glucose_2026-11-14"), daily()));
    await assertFails(deleteDoc(day(viewerDb(), "glucose_2026-11-13")));
    await assertSucceeds(deleteDoc(day(cgDb(), "glucose_2026-11-13")));
  });

  test("Daily summaries are readable by health readers only", async () => {
    await assertSucceeds(getDoc(day(cgDb(), "glucose_2026-11-13")));
    await assertFails(getDoc(day(viewerDb(), "glucose_2026-11-13")));
  });

});


describe("Prescribers / appointments / doctor notes rules — M16 step 2", () => {
  const ownerDb = () => testEnv.authenticatedContext("owner123").firestore();
  const cgDb = () => testEnv.authenticatedContext("caregiver123").firestore();
  const viewerDb = () => testEnv.authenticatedContext("viewer123").firestore();
  const hvDb = () => testEnv.authenticatedContext("hv123").firestore();
  const strangerDb = () => testEnv.authenticatedContext("stranger999").firestore();

  const pres = (db, id, pid = "profile1") => doc(db, "profiles", pid, "prescribers", id);
  const apt = (db, id, pid = "profile1") => doc(db, "profiles", pid, "appointments", id);
  const note = (db, id, pid = "profile1") => doc(db, "profiles", pid, "doctorNotes", id);

  const prescriber = (extra = {}) => ({
    name: "Dr. Ahmed Khan", createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
  });
  const future = () => new Date(Date.now() + 7 * 24 * 3600 * 1000);
  const appt = (extra = {}) => ({
    startsAt: future(), type: "follow_up", reminderOffsets: [1440, 120],
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
  });
  const noteDoc = (extra = {}) => ({
    body: "Ask about the dose", createdAt: serverTimestamp(), doneAt: null, ...extra,
  });
  const old = new Date("2026-11-01T10:00:00Z");

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "profiles", "profileHV"), {
        ownerUid: "owner123", kind: "self", name: "HV", timezone: "UTC",
        roles: { owner123: "owner", hv123: "viewer" },
        memberUids: ["owner123", "hv123"],
        healthUids: ["owner123", "hv123"],
        permissions: {},
      });
      // Solo Pro owner (M16 step 7 gates writes on the owner's subscription)
      await setDoc(doc(db, "customers", "owner123"), {
        activePlan: "annual_premium", status: "active",
      });
      await setDoc(pres(db, "p1"), { name: "Dr Old", createdAt: old, updatedAt: old });
      await setDoc(apt(db, "a1"), {
        startsAt: future(), type: "checkup", reminderOffsets: [1440, 120],
        createdAt: old, updatedAt: old,
      });
      await setDoc(note(db, "n1"), { body: "Old question", createdAt: old, doneAt: null });
    });
  });

  // ---------------- who can write ----------------

  test("Owner and caregiver can create all three", async () => {
    await assertSucceeds(setDoc(pres(ownerDb(), "x1"), prescriber()));
    await assertSucceeds(setDoc(pres(cgDb(), "x2"), prescriber()));
    await assertSucceeds(setDoc(apt(ownerDb(), "x1"), appt()));
    await assertSucceeds(setDoc(apt(cgDb(), "x2"), appt()));
    await assertSucceeds(setDoc(note(ownerDb(), "x1"), noteDoc()));
    await assertSucceeds(setDoc(note(cgDb(), "x2"), noteDoc()));
  });

  test("Viewers (with or without health access) and strangers cannot write", async () => {
    await assertFails(setDoc(pres(viewerDb(), "v1"), prescriber()));
    await assertFails(setDoc(pres(hvDb(), "v2", "profileHV"), prescriber()));
    await assertFails(setDoc(apt(hvDb(), "v3", "profileHV"), appt()));
    await assertFails(setDoc(note(hvDb(), "v4", "profileHV"), noteDoc()));
    await assertFails(setDoc(pres(strangerDb(), "v5"), prescriber()));
    await assertFails(setDoc(apt(strangerDb(), "v6"), appt()));
    await assertFails(setDoc(note(strangerDb(), "v7"), noteDoc()));
    await assertFails(updateDoc(pres(viewerDb(), "p1"), { name: "x" }));
    await assertFails(deleteDoc(pres(viewerDb(), "p1")));
    await assertFails(deleteDoc(apt(strangerDb(), "a1")));
  });

  test("Health readers can read, others cannot", async () => {
    await assertSucceeds(getDoc(pres(cgDb(), "p1")));
    await assertSucceeds(getDoc(apt(ownerDb(), "a1")));
    await assertSucceeds(getDoc(note(ownerDb(), "n1")));
    await assertFails(getDoc(pres(viewerDb(), "p1")));
    await assertFails(getDoc(note(strangerDb(), "n1")));
  });

  // ---------------- prescribers ----------------

  test("Prescriber with every optional field", async () => {
    await assertSucceeds(setDoc(pres(ownerDb(), "full"), prescriber({
      specialty: "GP", phone: "+1 (555) 987-6543", clinic: "City Care", address: "Maple Street",
    })));
  });

  test("Prescriber name rules", async () => {
    await assertFails(setDoc(pres(ownerDb(), "a"), prescriber({ name: "" })));
    await assertFails(setDoc(pres(ownerDb(), "b"), prescriber({ name: "a".repeat(81) })));
    await assertSucceeds(setDoc(pres(ownerDb(), "c"), prescriber({ name: "a".repeat(80) })));
    await assertFails(setDoc(pres(ownerDb(), "d"), prescriber({ name: 5 })));
    const d = prescriber();
    delete d.name;
    await assertFails(setDoc(pres(ownerDb(), "e"), d));
  });

  test("Prescriber phone rules", async () => {
    await assertSucceeds(setDoc(pres(ownerDb(), "p1x"), prescriber({ phone: "0300 1234567" })));
    await assertFails(setDoc(pres(ownerDb(), "p2x"), prescriber({ phone: "12345" })));
    await assertFails(setDoc(pres(ownerDb(), "p3x"), prescriber({ phone: "1".repeat(16) })));
    await assertSucceeds(setDoc(pres(ownerDb(), "p4x"), prescriber({ phone: "1".repeat(15) })));
    await assertFails(setDoc(pres(ownerDb(), "p5x"), prescriber({ phone: "abc1234567" })));
    await assertFails(setDoc(pres(ownerDb(), "p6x"), prescriber({ phone: 1234567 })));
  });

  test("Prescriber optional text limits and extra fields", async () => {
    await assertFails(setDoc(pres(ownerDb(), "l1"), prescriber({ specialty: "a".repeat(61) })));
    await assertFails(setDoc(pres(ownerDb(), "l2"), prescriber({ clinic: "a".repeat(81) })));
    await assertFails(setDoc(pres(ownerDb(), "l3"), prescriber({ address: "a".repeat(201) })));
    await assertFails(setDoc(pres(ownerDb(), "l4"), prescriber({ isAdmin: true })));
  });

  test("Prescriber timestamps are server-controlled", async () => {
    await assertFails(setDoc(pres(ownerDb(), "t1"), prescriber({ createdAt: new Date("2020-01-01") })));
    await assertFails(setDoc(pres(ownerDb(), "t2"), prescriber({ updatedAt: new Date("2020-01-01") })));
  });

  test("Prescriber update keeps createdAt, refreshes updatedAt", async () => {
    await assertSucceeds(setDoc(pres(ownerDb(), "p1"), {
      name: "Dr New", createdAt: old, updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(pres(ownerDb(), "p1"), {
      name: "Dr New", createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(pres(ownerDb(), "p1"), { name: "Dr New", createdAt: old, updatedAt: old }));
  });

  test("Caregiver can delete a prescriber", async () => {
    await assertSucceeds(deleteDoc(pres(cgDb(), "p1")));
  });

  // ---------------- appointments ----------------

  test("Appointment: each type and optional fields", async () => {
    for (const type of ["follow_up", "checkup", "lab_review", "other"]) {
      await assertSucceeds(setDoc(apt(ownerDb(), "t_" + type), appt({ type })));
    }
    await assertSucceeds(setDoc(apt(ownerDb(), "full"), appt({
      prescriberId: "p1", location: "City Care", notes: "Bring reports",
    })));
  });

  test("Appointment type, time and shape", async () => {
    await assertFails(setDoc(apt(ownerDb(), "a"), appt({ type: "surgery" })));
    await assertFails(setDoc(apt(ownerDb(), "b"), appt({ startsAt: "tomorrow" })));
    await assertFails(setDoc(apt(ownerDb(), "c"), appt({ extra: 1 })));
    const d = appt();
    delete d.startsAt;
    await assertFails(setDoc(apt(ownerDb(), "d"), d));
    const e = appt();
    delete e.reminderOffsets;
    await assertFails(setDoc(apt(ownerDb(), "e"), e));
  });

  test("Appointment text limits", async () => {
    await assertFails(setDoc(apt(ownerDb(), "a"), appt({ location: "a".repeat(201) })));
    await assertSucceeds(setDoc(apt(ownerDb(), "b"), appt({ location: "a".repeat(200) })));
    await assertFails(setDoc(apt(ownerDb(), "c"), appt({ notes: "a".repeat(501) })));
    await assertSucceeds(setDoc(apt(ownerDb(), "d"), appt({ notes: "a".repeat(500) })));
  });

  test("Appointment reminder offsets", async () => {
    await assertSucceeds(setDoc(apt(ownerDb(), "o0"), appt({ reminderOffsets: [] })));
    await assertSucceeds(setDoc(apt(ownerDb(), "o1"), appt({ reminderOffsets: [43200, 1440, 120, 30, 1] })));
    await assertFails(setDoc(apt(ownerDb(), "o2"), appt({ reminderOffsets: [60, 50, 40, 30, 20, 10] })));
    await assertFails(setDoc(apt(ownerDb(), "o3"), appt({ reminderOffsets: [0] })));
    await assertFails(setDoc(apt(ownerDb(), "o4"), appt({ reminderOffsets: [-5] })));
    await assertFails(setDoc(apt(ownerDb(), "o5"), appt({ reminderOffsets: [43201] })));
    await assertFails(setDoc(apt(ownerDb(), "o6"), appt({ reminderOffsets: [60, 60] })));
    await assertFails(setDoc(apt(ownerDb(), "o7"), appt({ reminderOffsets: [120, 1440] })));
    await assertFails(setDoc(apt(ownerDb(), "o8"), appt({ reminderOffsets: ["60"] })));
    await assertFails(setDoc(apt(ownerDb(), "o9"), appt({ reminderOffsets: 60 })));
    await assertFails(setDoc(apt(ownerDb(), "oA"), appt({ reminderOffsets: [60.5] })));
  });

  test("Appointment prescriber must exist in the same profile", async () => {
    await assertSucceeds(setDoc(apt(ownerDb(), "ok"), appt({ prescriberId: "p1" })));
    await assertFails(setDoc(apt(ownerDb(), "bad"), appt({ prescriberId: "ghost" })));
    await assertFails(setDoc(apt(ownerDb(), "empty"), appt({ prescriberId: "" })));
    await assertFails(setDoc(apt(ownerDb(), "num"), appt({ prescriberId: 5 })));
  });

  test("Appointment edit keeps createdAt and can move the time", async () => {
    await assertSucceeds(setDoc(apt(ownerDb(), "a1"), {
      startsAt: future(), type: "lab_review", reminderOffsets: [60],
      createdAt: old, updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(apt(ownerDb(), "a1"), {
      startsAt: future(), type: "lab_review", reminderOffsets: [60],
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
  });

  test("Caregiver can delete an appointment", async () => {
    await assertSucceeds(deleteDoc(apt(cgDb(), "a1")));
  });

  // ---------------- doctor notes ----------------

  test("Doctor note create rules", async () => {
    await assertSucceeds(setDoc(note(ownerDb(), "n2"), noteDoc({ appointmentId: "a1" })));
    await assertFails(setDoc(note(ownerDb(), "b1"), noteDoc({ body: "" })));
    await assertFails(setDoc(note(ownerDb(), "b2"), noteDoc({ body: "a".repeat(501) })));
    await assertSucceeds(setDoc(note(ownerDb(), "b3"), noteDoc({ body: "a".repeat(500) })));
    await assertFails(setDoc(note(ownerDb(), "b4"), noteDoc({ body: 5 })));
    await assertFails(setDoc(note(ownerDb(), "b5"), noteDoc({ extra: 1 })));
    await assertFails(setDoc(note(ownerDb(), "b6"), noteDoc({ appointmentId: "" })));
    await assertFails(setDoc(note(ownerDb(), "b7"), noteDoc({ createdAt: new Date("2020-01-01") })));
    await assertFails(setDoc(note(ownerDb(), "b8"), noteDoc({ doneAt: serverTimestamp() })));
    const d = noteDoc();
    delete d.doneAt;
    await assertFails(setDoc(note(ownerDb(), "b9"), d));
  });

  test("Doctor note can be ticked off, reopened and edited", async () => {
    await assertSucceeds(updateDoc(note(ownerDb(), "n1"), { doneAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(note(cgDb(), "n1"), { doneAt: null }));
    await assertSucceeds(updateDoc(note(ownerDb(), "n1"), { body: "Edited question" }));
  });

  test("Doctor note edits are limited", async () => {
    await assertFails(updateDoc(note(ownerDb(), "n1"), { doneAt: new Date("2020-01-01") }));
    await assertFails(updateDoc(note(ownerDb(), "n1"), { body: "" }));
    await assertFails(updateDoc(note(ownerDb(), "n1"), { body: "a".repeat(501) }));
    await assertFails(updateDoc(note(ownerDb(), "n1"), { createdAt: serverTimestamp() }));
    await assertFails(updateDoc(note(ownerDb(), "n1"), { appointmentId: "a1" }));
    await assertFails(updateDoc(note(ownerDb(), "n1"), { extra: 1 }));
    await assertFails(updateDoc(note(hvDb(), "n1", "profileHV"), { doneAt: serverTimestamp() }));
  });

  test("Caregiver can delete a doctor note", async () => {
    await assertSucceeds(deleteDoc(note(cgDb(), "n1")));
  });
});

describe("Solo Pro gate for prescribers / appointments / notes — M16 step 7", () => {
  const ownerDb = () => testEnv.authenticatedContext("owner123").firestore();
  const cgDb = () => testEnv.authenticatedContext("caregiver123").firestore();

  const pres = (db, id) => doc(db, "profiles", "profile1", "prescribers", id);
  const apt = (db, id) => doc(db, "profiles", "profile1", "appointments", id);
  const note = (db, id) => doc(db, "profiles", "profile1", "doctorNotes", id);

  const prescriber = () => ({
    name: "Dr. Gate", createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  });
  const appt = () => ({
    startsAt: new Date(Date.now() + 86400000), type: "checkup", reminderOffsets: [60],
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  });
  const noteDoc = () => ({ body: "Question", createdAt: serverTimestamp(), doneAt: null });

  const old = new Date("2026-11-01T10:00:00Z");
  const hour = 3600 * 1000;

  async function setCustomer(uid, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "customers", uid), data);
    });
  }

  async function writesAllowed() {
    // one create on each collection, with fresh ids
    const id = "g" + Math.random().toString(36).slice(2, 8);
    try {
      await assertSucceeds(setDoc(pres(ownerDb(), id), prescriber()));
      await assertSucceeds(setDoc(apt(ownerDb(), id), appt()));
      await assertSucceeds(setDoc(note(ownerDb(), id), noteDoc()));
      return true;
    } catch (_) {
      return false;
    }
  }

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(pres(db, "p1"), { name: "Dr Old", createdAt: old, updatedAt: old });
      await setDoc(apt(db, "a1"), {
        startsAt: new Date(Date.now() + 86400000), type: "checkup", reminderOffsets: [60],
        createdAt: old, updatedAt: old,
      });
      await setDoc(note(db, "n1"), { body: "Old", createdAt: old, doneAt: null });
    });
  });

  test("Owner without a subscription record cannot create or update", async () => {
    await assertFails(setDoc(pres(ownerDb(), "x"), prescriber()));
    await assertFails(setDoc(apt(ownerDb(), "x"), appt()));
    await assertFails(setDoc(note(ownerDb(), "x"), noteDoc()));
    await assertFails(updateDoc(pres(ownerDb(), "p1"), { name: "New", updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(note(ownerDb(), "n1"), { doneAt: serverTimestamp() }));
    await assertFails(updateDoc(note(ownerDb(), "n1"), { body: "Edited" }));
  });

  test("On the free plan existing data can still be read and deleted", async () => {
    await assertSucceeds(getDoc(pres(ownerDb(), "p1")));
    await assertSucceeds(getDoc(apt(ownerDb(), "a1")));
    await assertSucceeds(getDoc(note(ownerDb(), "n1")));
    await assertSucceeds(deleteDoc(pres(ownerDb(), "p1")));
    await assertSucceeds(deleteDoc(apt(ownerDb(), "a1")));
    await assertSucceeds(deleteDoc(note(ownerDb(), "n1")));
  });

  test("Active, trial and grace-period subscriptions can write", async () => {
    for (const status of ["active", "trial", "grace_period"]) {
      await setCustomer("owner123", { activePlan: "monthly_premium", status });
      expect(await writesAllowed()).toBe(true);
    }
  });

  test("An expired subscription cannot write", async () => {
    await setCustomer("owner123", { activePlan: "monthly_premium", status: "expired" });
    expect(await writesAllowed()).toBe(false);
  });

  test("Canceled but still inside the paid period can write; after it, cannot", async () => {
    await setCustomer("owner123", {
      activePlan: "monthly_premium", status: "canceled",
      expiresAt: new Date(Date.now() + 5 * 24 * hour),
    });
    expect(await writesAllowed()).toBe(true);

    await setCustomer("owner123", {
      activePlan: "monthly_premium", status: "canceled",
      expiresAt: new Date(Date.now() - 5 * 24 * hour),
    });
    expect(await writesAllowed()).toBe(false);

    await setCustomer("owner123", { activePlan: "monthly_premium", status: "canceled" });
    expect(await writesAllowed()).toBe(false); // no end date: not trusted
  });

  test("Updates are gated too, and work again after upgrading", async () => {
    await setCustomer("owner123", { activePlan: "monthly_premium", status: "expired" });
    await assertFails(updateDoc(apt(ownerDb(), "a1"), { notes: "x", updatedAt: serverTimestamp() }));

    await setCustomer("owner123", { activePlan: "annual_premium", status: "active" });
    await assertSucceeds(updateDoc(apt(ownerDb(), "a1"), { notes: "x", updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(note(ownerDb(), "n1"), { doneAt: serverTimestamp() }));
  });

  test("The profile OWNER's plan counts, not the caregiver's", async () => {
    // caregiver has Pro but the owner is free: denied
    await setCustomer("caregiver123", { activePlan: "monthly_premium", status: "active" });
    await assertFails(setDoc(note(cgDb(), "cg1"), noteDoc()));

    // owner is Pro, caregiver is free: allowed
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "customers", "owner123"), {
        activePlan: "family_plan", status: "active",
      });
      await setDoc(doc(context.firestore(), "customers", "caregiver123"), {
        activePlan: "free", status: "expired",
      });
    });
    await assertSucceeds(setDoc(note(cgDb(), "cg2"), noteDoc()));
    await assertSucceeds(setDoc(apt(cgDb(), "cg2"), appt()));
  });

  test("A client can never grant itself Pro", async () => {
    await assertFails(setDoc(doc(ownerDb(), "customers", "owner123"), {
      activePlan: "annual_premium", status: "active",
    }));
    await assertFails(setDoc(note(ownerDb(), "still-blocked"), noteDoc()));
  });
});
