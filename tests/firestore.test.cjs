
const fs = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");
const assert = require("node:assert/strict");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const rules = fs.readFileSync(
  path.join(__dirname, "..", "firestore.rules"),
  "utf8"
);

const projectId = "declarahorario";

const ids = {
  declarante: "declarante_prueba",
  otro: "otro_declarante_prueba",
  superior: "superior_prueba",
  rrhh: "rrhh_prueba",
  admin: "admin_prueba",
};

async function prepararEntorno() {
  const env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules,
    },
  });

  await env.clearFirestore();

  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    const usuarios = [
      {
        id: ids.declarante,
        rol: "declarante",
        superiorId: ids.superior,
      },
      {
        id: ids.otro,
        rol: "declarante",
      },
      {
        id: ids.superior,
        rol: "superior",
      },
      {
        id: ids.rrhh,
        rol: "rrhh",
      },
      {
        id: ids.admin,
        rol: "admin",
      },
    ];

    for (const usuario of usuarios) {
      await db.collection("users").doc(usuario.id).set({
        nombre: usuario.id,
        correo: `${usuario.id}@prueba.com`,
        rol: usuario.rol,
        ...(usuario.superiorId
          ? { superiorId: usuario.superiorId }
          : {}),
      });
    }

    await db.collection("declarations").doc("declaracion_prueba").set({
      usuarioId: ids.declarante,
      superiorId: ids.superior,
      estado: "BORRADOR",
      versionActual: 1,
      nombreFuncionario: "Funcionario de prueba",
    });
  });

  return env;
}

test("Permisos de lectura de declaraciones", async (t) => {
  const env = await prepararEntorno();

  try {
    const declaracion = (context) =>
      context
        .firestore()
        .collection("declarations")
        .doc("declaracion_prueba");

    await t.test("1. Sin iniciar sesión: acceso denegado", async () => {
      await assertFails(
        declaracion(env.unauthenticatedContext()).get()
      );
    });

    await t.test("2. Propietario: acceso permitido", async () => {
      await assertSucceeds(
        declaracion(
          env.authenticatedContext(ids.declarante)
        ).get()
      );
    });

    await t.test("3. Otro declarante: acceso denegado", async () => {
      await assertFails(
        declaracion(
          env.authenticatedContext(ids.otro)
        ).get()
      );
    });

    await t.test("4. Superior asignado: acceso permitido", async () => {
      await assertSucceeds(
        declaracion(
          env.authenticatedContext(ids.superior)
        ).get()
      );
    });

    await t.test("5. RR. HH.: acceso permitido", async () => {
      await assertSucceeds(
        declaracion(
          env.authenticatedContext(ids.rrhh)
        ).get()
      );
    });

    await t.test("6. Administración: acceso permitido", async () => {
      await assertSucceeds(
        declaracion(
          env.authenticatedContext(ids.admin)
        ).get()
      );
    });

    await t.test("7. Usuario sin perfil: acceso denegado", async () => {
      await assertFails(
        declaracion(
          env.authenticatedContext("usuario_desconocido")
        ).get()
      );
    });

    assert.ok(true);
  } finally {
    await env.cleanup();
  }
});
