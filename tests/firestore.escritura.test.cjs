
const fs = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

test("Permisos para crear declaraciones", async (t) => {
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

    // Preparar usuarios simulados sin aplicar las reglas.
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await db.collection("users").doc("declarante_prueba").set({
        nombre: "Declarante de prueba",
        rol: "declarante",
        superiorId: "superior_prueba",
      });

      await db.collection("users").doc("otro_declarante").set({
        nombre: "Otro declarante",
        rol: "declarante",
        superiorId: "superior_prueba",
      });

      await db.collection("users").doc("superior_prueba").set({
        nombre: "Superior de prueba",
        rol: "superior",
      });
    });

    function datosDeclaracion(usuarioId) {
      return {
        usuarioId,
        superiorId: "superior_prueba",
        estado: "BORRADOR",
        versionActual: 1,
        nombreFuncionario: "Funcionario de prueba",
      };
    }

    await t.test("1. Declarante crea su declaración", async () => {
      const db = env.authenticatedContext(
        "declarante_prueba"
      ).firestore();

      await assertSucceeds(
        db.collection("declarations")
          .doc("creacion_permitida")
          .set(datosDeclaracion("declarante_prueba"))
      );
    });

    await t.test("2. No puede crear a nombre de otro", async () => {
      const db = env.authenticatedContext(
        "declarante_prueba"
      ).firestore();

      await assertFails(
        db.collection("declarations")
          .doc("creacion_prohibida")
          .set(datosDeclaracion("otro_declarante"))
      );
    });

    await t.test("3. Superior no puede crear declaraciones", async () => {
      const db = env.authenticatedContext(
        "superior_prueba"
      ).firestore();

      await assertFails(
        db.collection("declarations")
          .doc("creacion_superior")
          .set(datosDeclaracion("superior_prueba"))
      );
    });

    await t.test("4. No puede crear una declaración VALIDADA", async () => {
      const db = env.authenticatedContext(
        "declarante_prueba"
      ).firestore();

      await assertFails(
        db.collection("declarations")
          .doc("estado_incorrecto")
          .set({
            ...datosDeclaracion("declarante_prueba"),
            estado: "VALIDADA",
          })
      );
    });
  } finally {
    await env.cleanup();
  }
});
