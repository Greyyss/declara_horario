
const fs = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

test("Seguridad de validación de declaraciones", async (t) => {
  const rules = fs.readFileSync(
    path.join(__dirname, "..", "firestore.rules"),
    "utf8"
  );

  const env = await initializeTestEnvironment({
    projectId: "declarahorario",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules,
    },
  });

  try {
    await env.clearFirestore();

    // Crear datos de prueba sin restricciones de seguridad.
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await db.collection("users").doc("declarante_prueba").set({
        nombre: "Declarante",
        rol: "declarante",
        superiorId: "superior_prueba",
      });

      await db.collection("users").doc("otro_declarante").set({
        nombre: "Otro declarante",
        rol: "declarante",
      });

      await db.collection("users").doc("superior_prueba").set({
        nombre: "Superior",
        rol: "superior",
      });

      const declaraciones = [
        ["validacion_correcta", "BORRADOR"],
        ["validacion_ajena", "BORRADOR"],
        ["estado_incorrecto", "BORRADOR"],
        ["modificacion_extra", "BORRADOR"],
        ["ya_validada", "VALIDADA"],
      ];

      for (const [id, estado] of declaraciones) {
        await db.collection("declarations").doc(id).set({
          usuarioId: "declarante_prueba",
          superiorId: "superior_prueba",
          nombreFuncionario: "Funcionario de prueba",
          estado,
          versionActual: 1,
        });
      }
    });

    const propietario = env
      .authenticatedContext("declarante_prueba")
      .firestore();

    const otro = env
      .authenticatedContext("otro_declarante")
      .firestore();

    const superior = env
      .authenticatedContext("superior_prueba")
      .firestore();

    await t.test("1. Propietario puede validar BORRADOR", async () => {
      await assertSucceeds(
        propietario
          .collection("declarations")
          .doc("validacion_correcta")
          .update({
            estado: "VALIDADA",
            fechaValidacion:
              require("firebase/compat/app").firestore
                .FieldValue.serverTimestamp(),
          })
      );
    });

    await t.test("2. Otro declarante no puede validar", async () => {
      await assertFails(
        otro
          .collection("declarations")
          .doc("validacion_ajena")
          .update({
            estado: "VALIDADA",
            fechaValidacion:
              require("firebase/compat/app").firestore
                .FieldValue.serverTimestamp(),
          })
      );
    });

    await t.test("3. No puede saltar directamente a FIRMADA", async () => {
      await assertFails(
        propietario
          .collection("declarations")
          .doc("estado_incorrecto")
          .update({
            estado: "FIRMADA_POR_DECLARANTE",
            fechaValidacion:
              require("firebase/compat/app").firestore
                .FieldValue.serverTimestamp(),
          })
      );
    });

    await t.test("4. No puede cambiar otros campos al validar", async () => {
      await assertFails(
        propietario
          .collection("declarations")
          .doc("modificacion_extra")
          .update({
            estado: "VALIDADA",
            nombreFuncionario: "Nombre modificado",
            fechaValidacion:
              require("firebase/compat/app").firestore
                .FieldValue.serverTimestamp(),
          })
      );
    });

    await t.test("5. No puede validar una declaración ya validada", async () => {
      await assertFails(
        propietario
          .collection("declarations")
          .doc("ya_validada")
          .update({
            estado: "VALIDADA",
            fechaValidacion:
              require("firebase/compat/app").firestore
                .FieldValue.serverTimestamp(),
          })
      );
    });

    await t.test("6. Superior no puede validar por el propietario", async () => {
      await assertFails(
        superior
          .collection("declarations")
          .doc("validacion_ajena")
          .update({
            estado: "VALIDADA",
            fechaValidacion:
              require("firebase/compat/app").firestore
                .FieldValue.serverTimestamp(),
          })
      );
    });
  } finally {
    await env.cleanup();
  }
});
