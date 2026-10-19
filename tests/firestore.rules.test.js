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
        active: true,
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
        { name: "Updated Medicine" }
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

    await assertFails(
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